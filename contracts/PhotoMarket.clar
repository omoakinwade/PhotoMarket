;; PhotoMarket - Photography portfolio monetization and visual content rewards platform
(define-data-var gallery-curator principal tx-sender)
(define-data-var total-photo-tokens uint u0)
(define-data-var visual-appreciation-rate uint u42) ;; appreciation tokens per photo engagement
(define-data-var last-curation-cycle uint u0)

(define-map photographer-portfolios principal uint)
(define-map photography-styles principal (string-utf8 64))
(define-map featured-styles (string-utf8 64) bool)

;; Error codes
(define-constant err-unauthorized-curator (err u2500))
(define-constant err-curator-already-appointed (err u2501))
(define-constant err-invalid-token-count (err u2502))
(define-constant err-no-appreciation-rewards (err u2503))
(define-constant err-no-portfolio-content (err u2504))
(define-constant err-invalid-photography-style (err u2505))
(define-constant err-style-not-featured (err u2506))

;; Verify curator authorization
(define-private (is-gallery-curator (caller principal))
  (begin
    (asserts! (is-eq caller (var-get gallery-curator)) err-unauthorized-curator)
    (ok true)))

;; Initialize photography portfolio monetization platform
(define-public (establish-photo-market (curator principal))
  (begin
    (asserts! (is-none (map-get? photographer-portfolios curator)) err-curator-already-appointed)
    (var-set gallery-curator curator)
    (ok "PhotoMarket photography monetization platform established")))

;; Feature photography style for portfolio monetization
(define-public (feature-photography-style (style (string-utf8 64)))
  (begin
    (try! (is-gallery-curator tx-sender))
    (asserts! (> (len style) u0) err-invalid-photography-style)
    (map-set featured-styles style true)
    (ok "Photography style featured for portfolio monetization")))

;; Upload photography portfolio content
(define-public (upload-portfolio-content (tokens uint) (photography-style (string-utf8 64)))
  (begin
    (asserts! (> tokens u0) err-invalid-token-count)
    (asserts! (default-to false (map-get? featured-styles photography-style)) err-style-not-featured)
    
    (let ((current-portfolio (default-to u0 (map-get? photographer-portfolios tx-sender))))
      (map-set photographer-portfolios tx-sender (+ current-portfolio tokens))
      (map-set photography-styles tx-sender photography-style)
      (var-set total-photo-tokens (+ (var-get total-photo-tokens) tokens))
      (ok (+ current-portfolio tokens)))))

;; Curate visual appreciation rewards
(define-public (curate-appreciation-rewards)
  (begin
    (try! (is-gallery-curator tx-sender))
    (let ((current-cycle (+ (var-get last-curation-cycle) u1))
          (total-tokens (var-get total-photo-tokens)))
      (asserts! (> total-tokens (var-get last-curation-cycle)) err-no-appreciation-rewards)
      
      (let ((appreciation-reward-pool (* (var-get visual-appreciation-rate) total-tokens)))
        (var-set last-curation-cycle current-cycle)
        (ok appreciation-reward-pool)))))

;; Monetize photography portfolio and claim rewards
(define-public (monetize-photography-portfolio)
  (begin
    (let ((photographer-token-portfolio (default-to u0 (map-get? photographer-portfolios tx-sender))))
      (asserts! (> photographer-token-portfolio u0) err-no-portfolio-content)
      
      (let ((total-tokens (var-get total-photo-tokens))
            (base-appreciation-rewards (* (var-get visual-appreciation-rate) photographer-token-portfolio))
            (portfolio-ratio (/ (* photographer-token-portfolio u100000) total-tokens)))
        
        (let ((final-photography-rewards (/ (* portfolio-ratio base-appreciation-rewards) u100000)))
          (map-delete photographer-portfolios tx-sender)
          (map-delete photography-styles tx-sender)
          (var-set total-photo-tokens (- (var-get total-photo-tokens) photographer-token-portfolio))
          (ok (+ photographer-token-portfolio final-photography-rewards)))))))

;; Read-only functions
(define-read-only (get-photographer-portfolio (photographer principal))
  (default-to u0 (map-get? photographer-portfolios photographer)))

(define-read-only (get-photography-style (photographer principal))
  (map-get? photography-styles photographer))

(define-read-only (get-total-photo-tokens)
  (var-get total-photo-tokens))

(define-read-only (is-style-featured (style (string-utf8 64)))
  (default-to false (map-get? featured-styles style)))