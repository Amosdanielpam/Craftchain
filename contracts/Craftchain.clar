(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ALREADY-EXISTS (err u101))
(define-constant ERR-NOT-FOUND (err u102))
(define-constant ERR-INSUFFICIENT-FUNDS (err u103))
(define-constant ERR-INVALID-AMOUNT (err u104))
(define-constant ERR-ALREADY-PURCHASED (err u105))
(define-constant ERR-CANNOT-RATE-OWN-PRODUCT (err u106))
(define-constant ERR-INVALID-RATING (err u107))
(define-constant ERR-PRODUCT-NOT-PURCHASED (err u108))
(define-constant ERR-SKILL-ALREADY-CERTIFIED (err u109))
(define-constant ERR-SKILL-NOT-CERTIFIED (err u110))
(define-constant ERR-ALREADY-ENDORSED (err u111))
(define-constant ERR-CANNOT-ENDORSE-SELF (err u112))
(define-constant ERR-ENDORSER-NOT-VERIFIED (err u113))
(define-constant ERR-INVALID-SKILL-LEVEL (err u114))

(define-data-var next-artisan-id uint u1)
(define-data-var next-product-id uint u1)
(define-data-var next-order-id uint u1)
(define-data-var platform-fee-percentage uint u250)
(define-data-var next-certification-id uint u1)

(define-map artisans
  uint
  {
    wallet: principal,
    name: (string-ascii 100),
    specialty: (string-ascii 50),
    location: (string-ascii 100),
    verification-status: bool,
    total-sales: uint,
    rating-sum: uint,
    rating-count: uint,
    joined-at: uint
  }
)

(define-map artisan-wallets principal uint)

(define-map products
  uint
  {
    artisan-id: uint,
    name: (string-ascii 100),
    description: (string-ascii 500),
    category: (string-ascii 50),
    price: uint,
    quantity: uint,
    image-hash: (string-ascii 64),
    created-at: uint,
    is-active: bool,
    total-sold: uint,
    rating-sum: uint,
    rating-count: uint
  }
)

(define-map orders
  uint
  {
    product-id: uint,
    buyer: principal,
    artisan-id: uint,
    quantity: uint,
    total-price: uint,
    order-status: (string-ascii 20),
    created-at: uint,
    shipped-at: (optional uint),
    delivered-at: (optional uint)
  }
)

(define-map product-ratings
  {product-id: uint, buyer: principal}
  {rating: uint, review: (string-ascii 500), created-at: uint}
)

(define-map purchased-products
  {buyer: principal, product-id: uint}
  bool
)

(define-map skill-certifications
  uint
  {
    artisan-id: uint,
    skill-name: (string-ascii 50),
    level: uint,
    certified-by: principal,
    certification-date: uint,
    expiry-date: uint,
    is-active: bool
  }
)

(define-map artisan-skills
  {artisan-id: uint, skill-name: (string-ascii 50)}
  uint
)

(define-map skill-endorsements
  {certification-id: uint, endorser-id: uint}
  {
    endorsement-message: (string-ascii 200),
    endorsement-date: uint
  }
)

(define-map certification-endorsement-count
  uint
  uint
)

(define-read-only (get-artisan (artisan-id uint))
  (map-get? artisans artisan-id)
)

(define-read-only (get-artisan-by-wallet (wallet principal))
  (match (map-get? artisan-wallets wallet)
    artisan-id (get-artisan artisan-id)
    none
  )
)

(define-read-only (get-product (product-id uint))
  (map-get? products product-id)
)

(define-read-only (get-order (order-id uint))
  (map-get? orders order-id)
)

(define-read-only (get-product-rating (product-id uint) (buyer principal))
  (map-get? product-ratings {product-id: product-id, buyer: buyer})
)

(define-read-only (has-purchased-product (buyer principal) (product-id uint))
  (default-to false (map-get? purchased-products {buyer: buyer, product-id: product-id}))
)

(define-read-only (get-artisan-rating (artisan-id uint))
  (match (get-artisan artisan-id)
    artisan (if (> (get rating-count artisan) u0)
              (/ (get rating-sum artisan) (get rating-count artisan))
              u0)
    u0
  )
)

(define-read-only (get-product-rating-average (product-id uint))
  (match (get-product product-id)
    product (if (> (get rating-count product) u0)
              (/ (get rating-sum product) (get rating-count product))
              u0)
    u0
  )
)

(define-read-only (get-platform-fee-percentage)
  (var-get platform-fee-percentage)
)

(define-read-only (get-skill-certification (certification-id uint))
  (map-get? skill-certifications certification-id)
)

(define-read-only (get-artisan-skill-certification (artisan-id uint) (skill-name (string-ascii 50)))
  (match (map-get? artisan-skills {artisan-id: artisan-id, skill-name: skill-name})
    certification-id (get-skill-certification certification-id)
    none
  )
)

(define-read-only (get-skill-endorsement (certification-id uint) (endorser-id uint))
  (map-get? skill-endorsements {certification-id: certification-id, endorser-id: endorser-id})
)

(define-read-only (get-certification-endorsement-count (certification-id uint))
  (default-to u0 (map-get? certification-endorsement-count certification-id))
)

(define-public (register-artisan (name (string-ascii 100)) (specialty (string-ascii 50)) (location (string-ascii 100)))
  (let
    (
      (artisan-id (var-get next-artisan-id))
      (current-block stacks-block-height)
    )
    (asserts! (is-none (map-get? artisan-wallets tx-sender)) ERR-ALREADY-EXISTS)
    (map-set artisans artisan-id
      {
        wallet: tx-sender,
        name: name,
        specialty: specialty,
        location: location,
        verification-status: false,
        total-sales: u0,
        rating-sum: u0,
        rating-count: u0,
        joined-at: current-block
      }
    )
    (map-set artisan-wallets tx-sender artisan-id)
    (var-set next-artisan-id (+ artisan-id u1))
    (ok artisan-id)
  )
)

(define-public (verify-artisan (artisan-id uint))
  (let
    (
      (artisan (unwrap! (get-artisan artisan-id) ERR-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (map-set artisans artisan-id (merge artisan {verification-status: true}))
    (ok true)
  )
)

(define-public (create-product 
  (name (string-ascii 100)) 
  (description (string-ascii 500)) 
  (category (string-ascii 50)) 
  (price uint) 
  (quantity uint) 
  (image-hash (string-ascii 64)))
  (let
    (
      (artisan-id (unwrap! (map-get? artisan-wallets tx-sender) ERR-NOT-AUTHORIZED))
      (product-id (var-get next-product-id))
      (current-block stacks-block-height)
    )
    (asserts! (> price u0) ERR-INVALID-AMOUNT)
    (asserts! (> quantity u0) ERR-INVALID-AMOUNT)
    (map-set products product-id
      {
        artisan-id: artisan-id,
        name: name,
        description: description,
        category: category,
        price: price,
        quantity: quantity,
        image-hash: image-hash,
        created-at: current-block,
        is-active: true,
        total-sold: u0,
        rating-sum: u0,
        rating-count: u0
      }
    )
    (var-set next-product-id (+ product-id u1))
    (ok product-id)
  )
)

(define-public (update-product-quantity (product-id uint) (new-quantity uint))
  (let
    (
      (product (unwrap! (get-product product-id) ERR-NOT-FOUND))
      (artisan-id (unwrap! (map-get? artisan-wallets tx-sender) ERR-NOT-AUTHORIZED))
    )
    (asserts! (is-eq (get artisan-id product) artisan-id) ERR-NOT-AUTHORIZED)
    (map-set products product-id (merge product {quantity: new-quantity}))
    (ok true)
  )
)

(define-public (purchase-product (product-id uint) (quantity uint))
  (let
    (
      (product (unwrap! (get-product product-id) ERR-NOT-FOUND))
      (artisan (unwrap! (get-artisan (get artisan-id product)) ERR-NOT-FOUND))
      (order-id (var-get next-order-id))
      (total-price (* (get price product) quantity))
      (platform-fee (/ (* total-price (var-get platform-fee-percentage)) u10000))
      (artisan-payment (- total-price platform-fee))
      (current-block stacks-block-height)
    )
    (asserts! (get is-active product) ERR-NOT-FOUND)
    (asserts! (>= (get quantity product) quantity) ERR-INSUFFICIENT-FUNDS)
    (asserts! (> quantity u0) ERR-INVALID-AMOUNT)
    
    (try! (stx-transfer? total-price tx-sender (as-contract tx-sender)))
    (try! (as-contract (stx-transfer? artisan-payment tx-sender (get wallet artisan))))
    
    (map-set products product-id 
      (merge product {
        quantity: (- (get quantity product) quantity),
        total-sold: (+ (get total-sold product) quantity)
      })
    )
    
    (map-set artisans (get artisan-id product)
      (merge artisan {total-sales: (+ (get total-sales artisan) quantity)})
    )
    
    (map-set orders order-id
      {
        product-id: product-id,
        buyer: tx-sender,
        artisan-id: (get artisan-id product),
        quantity: quantity,
        total-price: total-price,
        order-status: "pending",
        created-at: current-block,
        shipped-at: none,
        delivered-at: none
      }
    )
    
    (map-set purchased-products {buyer: tx-sender, product-id: product-id} true)
    (var-set next-order-id (+ order-id u1))
    (ok order-id)
  )
)

(define-public (update-order-status (order-id uint) (new-status (string-ascii 20)))
  (let
    (
      (order (unwrap! (get-order order-id) ERR-NOT-FOUND))
      (artisan-id (unwrap! (map-get? artisan-wallets tx-sender) ERR-NOT-AUTHORIZED))
      (current-block stacks-block-height)
    )
    (asserts! (is-eq (get artisan-id order) artisan-id) ERR-NOT-AUTHORIZED)
    (map-set orders order-id 
      (merge order {
        order-status: new-status,
        shipped-at: (if (is-eq new-status "shipped") (some current-block) (get shipped-at order)),
        delivered-at: (if (is-eq new-status "delivered") (some current-block) (get delivered-at order))
      })
    )
    (ok true)
  )
)

(define-public (rate-product (product-id uint) (rating uint) (review (string-ascii 500)))
  (let
    (
      (product (unwrap! (get-product product-id) ERR-NOT-FOUND))
      (artisan (unwrap! (get-artisan (get artisan-id product)) ERR-NOT-FOUND))
      (current-block stacks-block-height)
    )
    (asserts! (and (>= rating u1) (<= rating u5)) ERR-INVALID-RATING)
    (asserts! (has-purchased-product tx-sender product-id) ERR-PRODUCT-NOT-PURCHASED)
    (asserts! (not (is-eq tx-sender (get wallet artisan))) ERR-CANNOT-RATE-OWN-PRODUCT)
    (asserts! (is-none (get-product-rating product-id tx-sender)) ERR-ALREADY-EXISTS)
    
    (map-set product-ratings {product-id: product-id, buyer: tx-sender}
      {rating: rating, review: review, created-at: current-block}
    )
    
    (map-set products product-id
      (merge product {
        rating-sum: (+ (get rating-sum product) rating),
        rating-count: (+ (get rating-count product) u1)
      })
    )
    
    (map-set artisans (get artisan-id product)
      (merge artisan {
        rating-sum: (+ (get rating-sum artisan) rating),
        rating-count: (+ (get rating-count artisan) u1)
      })
    )
    (ok true)
  )
)

(define-public (set-platform-fee (new-fee-percentage uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (<= new-fee-percentage u1000) ERR-INVALID-AMOUNT)
    (var-set platform-fee-percentage new-fee-percentage)
    (ok true)
  )
)

(define-public (toggle-product-status (product-id uint))
  (let
    (
      (product (unwrap! (get-product product-id) ERR-NOT-FOUND))
      (artisan-id (unwrap! (map-get? artisan-wallets tx-sender) ERR-NOT-AUTHORIZED))
    )
    (asserts! (is-eq (get artisan-id product) artisan-id) ERR-NOT-AUTHORIZED)
    (map-set products product-id 
      (merge product {is-active: (not (get is-active product))})
    )
    (ok true)
  )
)

(define-public (create-skill-certification 
  (artisan-id uint) 
  (skill-name (string-ascii 50)) 
  (level uint) 
  (validity-years uint))
  (let
    (
      (artisan (unwrap! (get-artisan artisan-id) ERR-NOT-FOUND))
      (certification-id (var-get next-certification-id))
      (current-block stacks-block-height)
      (blocks-per-year u52560)
      (expiry-block (+ current-block (* validity-years blocks-per-year)))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (and (>= level u1) (<= level u5)) ERR-INVALID-SKILL-LEVEL)
    (asserts! (> validity-years u0) ERR-INVALID-AMOUNT)
    (asserts! (is-none (map-get? artisan-skills {artisan-id: artisan-id, skill-name: skill-name})) ERR-SKILL-ALREADY-CERTIFIED)
    
    (map-set skill-certifications certification-id
      {
        artisan-id: artisan-id,
        skill-name: skill-name,
        level: level,
        certified-by: tx-sender,
        certification-date: current-block,
        expiry-date: expiry-block,
        is-active: true
      }
    )
    
    (map-set artisan-skills {artisan-id: artisan-id, skill-name: skill-name} certification-id)
    (map-set certification-endorsement-count certification-id u0)
    (var-set next-certification-id (+ certification-id u1))
    (ok certification-id)
  )
)

(define-public (renew-skill-certification (certification-id uint) (validity-years uint))
  (let
    (
      (certification (unwrap! (get-skill-certification certification-id) ERR-NOT-FOUND))
      (current-block stacks-block-height)
      (blocks-per-year u52560)
      (new-expiry-block (+ current-block (* validity-years blocks-per-year)))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> validity-years u0) ERR-INVALID-AMOUNT)
    
    (map-set skill-certifications certification-id
      (merge certification {
        expiry-date: new-expiry-block,
        is-active: true
      })
    )
    (ok true)
  )
)

(define-public (revoke-skill-certification (certification-id uint))
  (let
    (
      (certification (unwrap! (get-skill-certification certification-id) ERR-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    
    (map-set skill-certifications certification-id
      (merge certification {is-active: false})
    )
    (ok true)
  )
)

(define-public (endorse-skill-certification 
  (certification-id uint) 
  (endorsement-message (string-ascii 200)))
  (let
    (
      (certification (unwrap! (get-skill-certification certification-id) ERR-NOT-FOUND))
      (endorser-artisan-id (unwrap! (map-get? artisan-wallets tx-sender) ERR-NOT-AUTHORIZED))
      (endorser (unwrap! (get-artisan endorser-artisan-id) ERR-NOT-FOUND))
      (current-block stacks-block-height)
      (current-endorsement-count (get-certification-endorsement-count certification-id))
    )
    (asserts! (get verification-status endorser) ERR-ENDORSER-NOT-VERIFIED)
    (asserts! (get is-active certification) ERR-SKILL-NOT-CERTIFIED)
    (asserts! (> (get expiry-date certification) current-block) ERR-SKILL-NOT-CERTIFIED)
    (asserts! (not (is-eq (get artisan-id certification) endorser-artisan-id)) ERR-CANNOT-ENDORSE-SELF)
    (asserts! (is-none (get-skill-endorsement certification-id endorser-artisan-id)) ERR-ALREADY-ENDORSED)
    
    (map-set skill-endorsements {certification-id: certification-id, endorser-id: endorser-artisan-id}
      {
        endorsement-message: endorsement-message,
        endorsement-date: current-block
      }
    )
    
    (map-set certification-endorsement-count certification-id (+ current-endorsement-count u1))
    (ok true)
  )
)

(define-public (remove-skill-endorsement (certification-id uint))
  (let
    (
      (certification (unwrap! (get-skill-certification certification-id) ERR-NOT-FOUND))
      (endorser-artisan-id (unwrap! (map-get? artisan-wallets tx-sender) ERR-NOT-AUTHORIZED))
      (endorsement (unwrap! (get-skill-endorsement certification-id endorser-artisan-id) ERR-NOT-FOUND))
      (current-endorsement-count (get-certification-endorsement-count certification-id))
    )
    (map-delete skill-endorsements {certification-id: certification-id, endorser-id: endorser-artisan-id})
    (map-set certification-endorsement-count certification-id (- current-endorsement-count u1))
    (ok true)
  )
)
