;; Entity Verification Contract
;; Validates supply chain participants

(define-data-var admin principal tx-sender)

;; Entity status: 0 = unverified, 1 = pending, 2 = verified, 3 = rejected
(define-map entities
  { entity-id: (string-utf8 36) }
  {
    owner: principal,
    name: (string-utf8 100),
    entity-type: (string-utf8 20),
    status: uint,
    verification-date: uint
  }
)

(define-read-only (get-entity (entity-id (string-utf8 36)))
  (map-get? entities { entity-id: entity-id })
)

(define-public (register-entity
    (entity-id (string-utf8 36))
    (name (string-utf8 100))
    (entity-type (string-utf8 20))
  )
  (let ((existing-entity (get-entity entity-id)))
    (asserts! (is-none existing-entity) (err u1)) ;; Entity ID already exists
    (ok (map-set entities
      { entity-id: entity-id }
      {
        owner: tx-sender,
        name: name,
        entity-type: entity-type,
        status: u1, ;; Set to pending by default
        verification-date: u0
      }
    ))
  )
)

(define-public (verify-entity (entity-id (string-utf8 36)) (new-status uint))
  (let ((entity (unwrap! (get-entity entity-id) (err u2)))) ;; Entity not found
    (asserts! (is-eq tx-sender (var-get admin)) (err u3)) ;; Not authorized
    (asserts! (<= new-status u3) (err u4)) ;; Invalid status
    (ok (map-set entities
      { entity-id: entity-id }
      (merge entity {
        status: new-status,
        verification-date: block-height
      })
    ))
  )
)

(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u3)) ;; Not authorized
    (ok (var-set admin new-admin))
  )
)

(define-read-only (is-verified (entity-id (string-utf8 36)))
  (let ((entity (get-entity entity-id)))
    (if (is-some entity)
      (is-eq (get status (unwrap-panic entity)) u2)
      false
    )
  )
)
