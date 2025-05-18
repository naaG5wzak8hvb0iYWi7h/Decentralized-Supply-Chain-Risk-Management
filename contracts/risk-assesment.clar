;; Risk Assessment Contract
;; Identifies potential disruption factors

(define-data-var admin principal tx-sender)

;; Risk severity: 1 = low, 2 = medium, 3 = high, 4 = critical
(define-map risk-factors
  { risk-id: (string-utf8 36) }
  {
    name: (string-utf8 100),
    description: (string-utf8 500),
    severity: uint,
    category: (string-utf8 50),
    created-by: principal,
    created-at: uint,
    updated-at: uint
  }
)

;; Map entity to its risk assessments
(define-map entity-risks
  { entity-id: (string-utf8 36), risk-id: (string-utf8 36) }
  {
    impact-score: uint,
    probability: uint,
    assessment-date: uint,
    assessed-by: principal
  }
)

(define-read-only (get-risk-factor (risk-id (string-utf8 36)))
  (map-get? risk-factors { risk-id: risk-id })
)

(define-read-only (get-entity-risk (entity-id (string-utf8 36)) (risk-id (string-utf8 36)))
  (map-get? entity-risks { entity-id: entity-id, risk-id: risk-id })
)

(define-public (add-risk-factor
    (risk-id (string-utf8 36))
    (name (string-utf8 100))
    (description (string-utf8 500))
    (severity uint)
    (category (string-utf8 50))
  )
  (begin
    (asserts! (and (>= severity u1) (<= severity u4)) (err u1)) ;; Invalid severity
    (asserts! (is-none (get-risk-factor risk-id)) (err u2)) ;; Risk ID already exists
    (ok (map-set risk-factors
      { risk-id: risk-id }
      {
        name: name,
        description: description,
        severity: severity,
        category: category,
        created-by: tx-sender,
        created-at: block-height,
        updated-at: block-height
      }
    ))
  )
)

(define-public (update-risk-factor
    (risk-id (string-utf8 36))
    (name (string-utf8 100))
    (description (string-utf8 500))
    (severity uint)
    (category (string-utf8 50))
  )
  (let ((risk (unwrap! (get-risk-factor risk-id) (err u3)))) ;; Risk not found
    (asserts! (and (>= severity u1) (<= severity u4)) (err u1)) ;; Invalid severity
    (asserts! (or (is-eq tx-sender (var-get admin)) (is-eq tx-sender (get created-by risk))) (err u4)) ;; Not authorized
    (ok (map-set risk-factors
      { risk-id: risk-id }
      (merge risk {
        name: name,
        description: description,
        severity: severity,
        category: category,
        updated-at: block-height
      })
    ))
  )
)

(define-public (assess-entity-risk
    (entity-id (string-utf8 36))
    (risk-id (string-utf8 36))
    (impact-score uint)
    (probability uint)
  )
  (begin
    (asserts! (is-some (get-risk-factor risk-id)) (err u3)) ;; Risk not found
    (asserts! (and (>= impact-score u1) (<= impact-score u10)) (err u5)) ;; Invalid impact score
    (asserts! (and (>= probability u1) (<= probability u10)) (err u6)) ;; Invalid probability
    (ok (map-set entity-risks
      { entity-id: entity-id, risk-id: risk-id }
      {
        impact-score: impact-score,
        probability: probability,
        assessment-date: block-height,
        assessed-by: tx-sender
      }
    ))
  )
)

(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u4)) ;; Not authorized
    (ok (var-set admin new-admin))
  )
)
