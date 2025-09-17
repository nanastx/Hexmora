;; Hexmora - Gamified Smart Contract Toolkit with Marketplace
;; A modular system for crafting reusable Clarity contract components ("hexes")

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_HEX_NOT_FOUND (err u101))
(define-constant ERR_HEX_ALREADY_EXISTS (err u102))
(define-constant ERR_INVALID_PARAMETERS (err u103))
(define-constant ERR_INSUFFICIENT_BALANCE (err u104))
(define-constant ERR_HEX_INACTIVE (err u105))
(define-constant ERR_MARKETPLACE_LISTING_NOT_FOUND (err u106))
(define-constant ERR_ALREADY_LISTED (err u107))
(define-constant ERR_CANNOT_BUY_OWN_HEX (err u108))
(define-constant ERR_INSUFFICIENT_STX_BALANCE (err u109))
(define-constant ERR_HEX_NOT_FOR_SALE (err u110))

;; Data Variables
(define-data-var hex-counter uint u0)
(define-data-var total-hexes-crafted uint u0)
(define-data-var marketplace-listing-counter uint u0)

;; Data Maps
(define-map hexes 
  { hex-id: uint }
  { 
    creator: principal,
    name: (string-ascii 50),
    description: (string-ascii 200),
    hex-type: (string-ascii 20),
    power-level: uint,
    mana-cost: uint,
    is-active: bool,
    usage-count: uint,
    created-at: uint
  })

(define-map hex-components
  { hex-id: uint }
  {
    input-params: (list 10 (string-ascii 50)),
    output-format: (string-ascii 100),
    logic-hash: (buff 32)
  })

(define-map user-grimoire
  { user: principal }
  {
    total-hexes: uint,
    mana-balance: uint,
    experience-points: uint,
    last-craft-time: uint
  })

(define-map hex-ownership
  { hex-id: uint, owner: principal }
  { owned: bool })

;; Marketplace Maps
(define-map marketplace-listings
  { listing-id: uint }
  {
    hex-id: uint,
    seller: principal,
    price-ustx: uint,
    listed-at: uint,
    is-active: bool
  })

(define-map hex-marketplace-status
  { hex-id: uint }
  {
    is-listed: bool,
    listing-id: uint,
    current-price: uint
  })

;; Read-only functions
(define-read-only (get-hex-details (hex-id uint))
  (map-get? hexes { hex-id: hex-id }))

(define-read-only (get-hex-components (hex-id uint))
  (map-get? hex-components { hex-id: hex-id }))

(define-read-only (get-user-grimoire (user principal))
  (map-get? user-grimoire { user: user }))

(define-read-only (get-hex-counter)
  (var-get hex-counter))

(define-read-only (get-total-hexes-crafted)
  (var-get total-hexes-crafted))

(define-read-only (is-hex-owner (hex-id uint) (user principal))
  (default-to false (get owned (map-get? hex-ownership { hex-id: hex-id, owner: user }))))

(define-read-only (calculate-mana-cost (power-level uint))
  (if (<= power-level u10)
    (* power-level u5)
    (+ u50 (* (- power-level u10) u10))))

(define-read-only (get-marketplace-listing (listing-id uint))
  (map-get? marketplace-listings { listing-id: listing-id }))

(define-read-only (get-hex-marketplace-status (hex-id uint))
  (map-get? hex-marketplace-status { hex-id: hex-id }))

(define-read-only (get-marketplace-listing-counter)
  (var-get marketplace-listing-counter))

;; Private functions
(define-private (validate-hex-params (name (string-ascii 50)) (description (string-ascii 200)) (hex-type (string-ascii 20)) (power-level uint))
  (and 
    (> (len name) u0)
    (> (len description) u0)
    (> (len hex-type) u0)
    (and (> power-level u0) (<= power-level u100))))

(define-private (update-user-experience (user principal) (exp-gained uint))
  (let ((current-grimoire (default-to 
                            { total-hexes: u0, mana-balance: u100, experience-points: u0, last-craft-time: u0 }
                            (map-get? user-grimoire { user: user }))))
    (map-set user-grimoire 
      { user: user }
      (merge current-grimoire { 
        experience-points: (+ (get experience-points current-grimoire) exp-gained),
        last-craft-time: stacks-block-height 
      }))))

(define-private (validate-listing-params (hex-id uint) (price-ustx uint))
  (and
    (> hex-id u0)
    (> price-ustx u0)
    (<= price-ustx u1000000000))) ;; Max 1000 STX

(define-private (transfer-hex-ownership (hex-id uint) (from principal) (to principal))
  (begin
    ;; Remove ownership from seller
    (map-delete hex-ownership { hex-id: hex-id, owner: from })
    ;; Add ownership to buyer
    (map-set hex-ownership { hex-id: hex-id, owner: to } { owned: true })
    ;; Update buyer's grimoire
    (let ((buyer-grimoire (default-to 
                            { total-hexes: u0, mana-balance: u100, experience-points: u0, last-craft-time: u0 }
                            (map-get? user-grimoire { user: to }))))
      (map-set user-grimoire
        { user: to }
        (merge buyer-grimoire { 
          total-hexes: (+ (get total-hexes buyer-grimoire) u1)
        })))
    true))

;; Public functions
(define-public (craft-hex 
  (name (string-ascii 50))
  (description (string-ascii 200))
  (hex-type (string-ascii 20))
  (power-level uint)
  (input-params (list 10 (string-ascii 50)))
  (output-format (string-ascii 100))
  (validated-logic-hash (buff 32)))
  (let ((hex-id (+ (var-get hex-counter) u1))
        (mana-cost (calculate-mana-cost power-level))
        (current-grimoire (default-to 
                            { total-hexes: u0, mana-balance: u100, experience-points: u0, last-craft-time: u0 }
                            (map-get? user-grimoire { user: tx-sender }))))
    (asserts! (validate-hex-params name description hex-type power-level) ERR_INVALID_PARAMETERS)
    (asserts! (>= (get mana-balance current-grimoire) mana-cost) ERR_INSUFFICIENT_BALANCE)
    (asserts! (<= (len input-params) u10) ERR_INVALID_PARAMETERS)
    (asserts! (> (len output-format) u0) ERR_INVALID_PARAMETERS)
    (asserts! (> (len validated-logic-hash) u0) ERR_INVALID_PARAMETERS)
    
    ;; Create the hex
    (map-set hexes
      { hex-id: hex-id }
      {
        creator: tx-sender,
        name: name,
        description: description,
        hex-type: hex-type,
        power-level: power-level,
        mana-cost: mana-cost,
        is-active: true,
        usage-count: u0,
        created-at: stacks-block-height
      })
    
    ;; Set hex components
    (map-set hex-components
      { hex-id: hex-id }
      {
        input-params: input-params,
        output-format: output-format,
        logic-hash: validated-logic-hash
      })
    
    ;; Set ownership
    (map-set hex-ownership
      { hex-id: hex-id, owner: tx-sender }
      { owned: true })
    
    ;; Initialize marketplace status
    (map-set hex-marketplace-status
      { hex-id: hex-id }
      {
        is-listed: false,
        listing-id: u0,
        current-price: u0
      })
    
    ;; Update user grimoire
    (map-set user-grimoire
      { user: tx-sender }
      {
        total-hexes: (+ (get total-hexes current-grimoire) u1),
        mana-balance: (- (get mana-balance current-grimoire) mana-cost),
        experience-points: (+ (get experience-points current-grimoire) (* power-level u2)),
        last-craft-time: stacks-block-height
      })
    
    ;; Update counters
    (var-set hex-counter hex-id)
    (var-set total-hexes-crafted (+ (var-get total-hexes-crafted) u1))
    
    (ok hex-id)))

(define-public (activate-hex (validated-hex-id uint) (target-params (list 10 uint)))
  (let ((hex-data (unwrap! (map-get? hexes { hex-id: validated-hex-id }) ERR_HEX_NOT_FOUND))
        (current-grimoire (default-to 
                            { total-hexes: u0, mana-balance: u100, experience-points: u0, last-craft-time: u0 }
                            (map-get? user-grimoire { user: tx-sender }))))
    (asserts! (> validated-hex-id u0) ERR_INVALID_PARAMETERS)
    (asserts! (get is-active hex-data) ERR_HEX_INACTIVE)
    (asserts! (>= (get mana-balance current-grimoire) (get mana-cost hex-data)) ERR_INSUFFICIENT_BALANCE)
    (asserts! (<= (len target-params) u10) ERR_INVALID_PARAMETERS)
    
    ;; Update hex usage
    (map-set hexes
      { hex-id: validated-hex-id }
      (merge hex-data { usage-count: (+ (get usage-count hex-data) u1) }))
    
    ;; Deduct mana cost
    (map-set user-grimoire
      { user: tx-sender }
      (merge current-grimoire { 
        mana-balance: (- (get mana-balance current-grimoire) (get mana-cost hex-data))
      }))
    
    ;; Grant experience to creator if different from activator
    (if (not (is-eq tx-sender (get creator hex-data)))
      (update-user-experience (get creator hex-data) u1)
      true)
    
    (ok true)))

(define-public (recharge-mana (amount uint))
  (let ((current-grimoire (default-to 
                            { total-hexes: u0, mana-balance: u100, experience-points: u0, last-craft-time: u0 }
                            (map-get? user-grimoire { user: tx-sender }))))
    (asserts! (and (> amount u0) (<= amount u1000)) ERR_INVALID_PARAMETERS)
    
    (map-set user-grimoire
      { user: tx-sender }
      (merge current-grimoire { 
        mana-balance: (+ (get mana-balance current-grimoire) amount)
      }))
    
    (ok true)))

(define-public (toggle-hex-status (validated-hex-id uint))
  (let ((hex-data (unwrap! (map-get? hexes { hex-id: validated-hex-id }) ERR_HEX_NOT_FOUND)))
    (asserts! (> validated-hex-id u0) ERR_INVALID_PARAMETERS)
    (asserts! (is-eq tx-sender (get creator hex-data)) ERR_NOT_AUTHORIZED)
    
    (map-set hexes
      { hex-id: validated-hex-id }
      (merge hex-data { is-active: (not (get is-active hex-data)) }))
    
    (ok (not (get is-active hex-data)))))

;; Marketplace Functions
(define-public (list-hex-for-sale (hex-id uint) (price-ustx uint))
  (let ((hex-data (unwrap! (map-get? hexes { hex-id: hex-id }) ERR_HEX_NOT_FOUND))
        (marketplace-status (unwrap! (map-get? hex-marketplace-status { hex-id: hex-id }) ERR_HEX_NOT_FOUND))
        (listing-id (+ (var-get marketplace-listing-counter) u1)))
    
    (asserts! (validate-listing-params hex-id price-ustx) ERR_INVALID_PARAMETERS)
    (asserts! (is-hex-owner hex-id tx-sender) ERR_NOT_AUTHORIZED)
    (asserts! (not (get is-listed marketplace-status)) ERR_ALREADY_LISTED)
    (asserts! (get is-active hex-data) ERR_HEX_INACTIVE)
    
    ;; Create marketplace listing
    (map-set marketplace-listings
      { listing-id: listing-id }
      {
        hex-id: hex-id,
        seller: tx-sender,
        price-ustx: price-ustx,
        listed-at: stacks-block-height,
        is-active: true
      })
    
    ;; Update hex marketplace status
    (map-set hex-marketplace-status
      { hex-id: hex-id }
      {
        is-listed: true,
        listing-id: listing-id,
        current-price: price-ustx
      })
    
    ;; Update counter
    (var-set marketplace-listing-counter listing-id)
    
    (ok listing-id)))

(define-public (remove-hex-listing (hex-id uint))
  (let ((marketplace-status (unwrap! (map-get? hex-marketplace-status { hex-id: hex-id }) ERR_HEX_NOT_FOUND))
        (listing-data (unwrap! (map-get? marketplace-listings { listing-id: (get listing-id marketplace-status) }) ERR_MARKETPLACE_LISTING_NOT_FOUND)))
    
    (asserts! (> hex-id u0) ERR_INVALID_PARAMETERS)
    (asserts! (is-hex-owner hex-id tx-sender) ERR_NOT_AUTHORIZED)
    (asserts! (get is-listed marketplace-status) ERR_HEX_NOT_FOR_SALE)
    
    ;; Deactivate listing
    (map-set marketplace-listings
      { listing-id: (get listing-id marketplace-status) }
      (merge listing-data { is-active: false }))
    
    ;; Update hex marketplace status
    (map-set hex-marketplace-status
      { hex-id: hex-id }
      {
        is-listed: false,
        listing-id: u0,
        current-price: u0
      })
    
    (ok true)))

(define-public (buy-hex (listing-id uint))
  (let ((listing-data (unwrap! (map-get? marketplace-listings { listing-id: listing-id }) ERR_MARKETPLACE_LISTING_NOT_FOUND))
        (hex-id (get hex-id listing-data))
        (seller (get seller listing-data))
        (price (get price-ustx listing-data)))
    
    (asserts! (> listing-id u0) ERR_INVALID_PARAMETERS)
    (asserts! (get is-active listing-data) ERR_MARKETPLACE_LISTING_NOT_FOUND)
    (asserts! (not (is-eq tx-sender seller)) ERR_CANNOT_BUY_OWN_HEX)
    (asserts! (>= (stx-get-balance tx-sender) price) ERR_INSUFFICIENT_STX_BALANCE)
    
    ;; Transfer STX from buyer to seller
    (try! (stx-transfer? price tx-sender seller))
    
    ;; Transfer hex ownership
    (transfer-hex-ownership hex-id seller tx-sender)
    
    ;; Deactivate listing
    (map-set marketplace-listings
      { listing-id: listing-id }
      (merge listing-data { is-active: false }))
    
    ;; Update hex marketplace status
    (map-set hex-marketplace-status
      { hex-id: hex-id }
      {
        is-listed: false,
        listing-id: u0,
        current-price: u0
      })
    
    ;; Grant experience points to both parties
    (update-user-experience seller u5)
    (update-user-experience tx-sender u3)
    
    (ok hex-id)))

(define-public (update-hex-price (hex-id uint) (new-price-ustx uint))
  (let ((marketplace-status (unwrap! (map-get? hex-marketplace-status { hex-id: hex-id }) ERR_HEX_NOT_FOUND))
        (listing-data (unwrap! (map-get? marketplace-listings { listing-id: (get listing-id marketplace-status) }) ERR_MARKETPLACE_LISTING_NOT_FOUND)))
    
    (asserts! (> hex-id u0) ERR_INVALID_PARAMETERS)
    (asserts! (and (> new-price-ustx u0) (<= new-price-ustx u1000000000)) ERR_INVALID_PARAMETERS)
    (asserts! (is-hex-owner hex-id tx-sender) ERR_NOT_AUTHORIZED)
    (asserts! (get is-listed marketplace-status) ERR_HEX_NOT_FOR_SALE)
    (asserts! (get is-active listing-data) ERR_MARKETPLACE_LISTING_NOT_FOUND)
    
    ;; Update listing price
    (map-set marketplace-listings
      { listing-id: (get listing-id marketplace-status) }
      (merge listing-data { price-ustx: new-price-ustx }))
    
    ;; Update marketplace status
    (map-set hex-marketplace-status
      { hex-id: hex-id }
      (merge marketplace-status { current-price: new-price-ustx }))
    
    (ok true)))

;; Initialize contract owner's grimoire
(map-set user-grimoire
  { user: CONTRACT_OWNER }
  {
    total-hexes: u0,
    mana-balance: u1000,
    experience-points: u100,
    last-craft-time: stacks-block-height
  })