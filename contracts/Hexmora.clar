;; Hexmora - Gamified Smart Contract Toolkit
;; A modular system for crafting reusable Clarity contract components ("hexes")

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_HEX_NOT_FOUND (err u101))
(define-constant ERR_HEX_ALREADY_EXISTS (err u102))
(define-constant ERR_INVALID_PARAMETERS (err u103))
(define-constant ERR_INSUFFICIENT_BALANCE (err u104))
(define-constant ERR_HEX_INACTIVE (err u105))

;; Data Variables
(define-data-var hex-counter uint u0)
(define-data-var total-hexes-crafted uint u0)

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

;; Initialize contract owner's grimoire
(map-set user-grimoire
  { user: CONTRACT_OWNER }
  {
    total-hexes: u0,
    mana-balance: u1000,
    experience-points: u100,
    last-craft-time: stacks-block-height
  })