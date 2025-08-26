;; Facility Manager Contract
;; Manages 3D printing facility registration, capacity, and performance tracking

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-FACILITY-NOT-FOUND (err u101))
(define-constant ERR-FACILITY-ALREADY-EXISTS (err u102))
(define-constant ERR-INVALID-CAPACITY (err u103))
(define-constant ERR-INSUFFICIENT-CAPACITY (err u104))
(define-constant ERR-INVALID-RATING (err u105))
(define-constant ERR-FACILITY-INACTIVE (err u106))
(define-constant ERR-INVALID-INPUT (err u107))

;; Data Variables
(define-data-var next-facility-id uint u1)
(define-data-var total-facilities uint u0)

;; Data Maps
(define-map facilities uint {
  owner: principal,
  name: (string-ascii 50),
  location: (string-ascii 100),
  capacity: uint,
  available-capacity: uint,
  specializations: (list 10 (string-ascii 30)),
  rating: uint,
  total-jobs: uint,
  completed-jobs: uint,
  active: bool,
  created-at: uint
})

(define-map facility-owners principal uint)
(define-map facility-ratings uint {
  total-rating: uint,
  rating-count: uint,
  average-rating: uint
})

;; Public Functions

;; Register a new facility
(define-public (register-facility
  (name (string-ascii 50))
  (location (string-ascii 100))
  (capacity uint)
  (specializations (list 10 (string-ascii 30))))
  (let ((facility-id (var-get next-facility-id)))
    (asserts! (> capacity u0) ERR-INVALID-CAPACITY)
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (> (len location) u0) ERR-INVALID-INPUT)
    (asserts! (is-none (map-get? facility-owners tx-sender)) ERR-FACILITY-ALREADY-EXISTS)

    (map-set facilities facility-id {
      owner: tx-sender,
      name: name,
      location: location,
      capacity: capacity,
      available-capacity: capacity,
      specializations: specializations,
      rating: u0,
      total-jobs: u0,
      completed-jobs: u0,
      active: true,
      created-at: block-height
    })

    (map-set facility-owners tx-sender facility-id)
    (map-set facility-ratings facility-id {
      total-rating: u0,
      rating-count: u0,
      average-rating: u0
    })

    (var-set next-facility-id (+ facility-id u1))
    (var-set total-facilities (+ (var-get total-facilities) u1))

    (print {event: "facility-registered", facility-id: facility-id, owner: tx-sender})
    (ok facility-id)))

;; Update facility capacity
(define-public (update-capacity (facility-id uint) (new-capacity uint))
  (let ((facility (unwrap! (map-get? facilities facility-id) ERR-FACILITY-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get owner facility)) ERR-NOT-AUTHORIZED)
    (asserts! (> new-capacity u0) ERR-INVALID-CAPACITY)
    (asserts! (get active facility) ERR-FACILITY-INACTIVE)

    (let ((used-capacity (- (get capacity facility) (get available-capacity facility))))
      (asserts! (>= new-capacity used-capacity) ERR-INSUFFICIENT-CAPACITY)

      (map-set facilities facility-id (merge facility {
        capacity: new-capacity,
        available-capacity: (- new-capacity used-capacity)
      }))

      (print {event: "capacity-updated", facility-id: facility-id, new-capacity: new-capacity})
      (ok true))))

;; Reserve capacity for a job
(define-public (reserve-capacity (facility-id uint) (amount uint))
  (let ((facility (unwrap! (map-get? facilities facility-id) ERR-FACILITY-NOT-FOUND)))
    (asserts! (get active facility) ERR-FACILITY-INACTIVE)
    (asserts! (>= (get available-capacity facility) amount) ERR-INSUFFICIENT-CAPACITY)

    (map-set facilities facility-id (merge facility {
      available-capacity: (- (get available-capacity facility) amount),
      total-jobs: (+ (get total-jobs facility) u1)
    }))

    (print {event: "capacity-reserved", facility-id: facility-id, amount: amount})
    (ok true)))

;; Release capacity after job completion
(define-public (release-capacity (facility-id uint) (amount uint))
  (let ((facility (unwrap! (map-get? facilities facility-id) ERR-FACILITY-NOT-FOUND)))
    (map-set facilities facility-id (merge facility {
      available-capacity: (+ (get available-capacity facility) amount),
      completed-jobs: (+ (get completed-jobs facility) u1)
    }))

    (print {event: "capacity-released", facility-id: facility-id, amount: amount})
    (ok true)))

;; Rate a facility
(define-public (rate-facility (facility-id uint) (rating uint))
  (let ((facility (unwrap! (map-get? facilities facility-id) ERR-FACILITY-NOT-FOUND))
        (current-ratings (unwrap! (map-get? facility-ratings facility-id) ERR-FACILITY-NOT-FOUND)))
    (asserts! (and (>= rating u1) (<= rating u5)) ERR-INVALID-RATING)
    (asserts! (get active facility) ERR-FACILITY-INACTIVE)

    (let ((new-total-rating (+ (get total-rating current-ratings) rating))
          (new-rating-count (+ (get rating-count current-ratings) u1)))
      (let ((new-average (/ new-total-rating new-rating-count)))
        (map-set facility-ratings facility-id {
          total-rating: new-total-rating,
          rating-count: new-rating-count,
          average-rating: new-average
        })

        (map-set facilities facility-id (merge facility {
          rating: new-average
        }))

        (print {event: "facility-rated", facility-id: facility-id, rating: rating, new-average: new-average})
        (ok true)))))

;; Update facility specializations
(define-public (update-specializations
  (facility-id uint)
  (specializations (list 10 (string-ascii 30))))
  (let ((facility (unwrap! (map-get? facilities facility-id) ERR-FACILITY-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get owner facility)) ERR-NOT-AUTHORIZED)
    (asserts! (get active facility) ERR-FACILITY-INACTIVE)

    (map-set facilities facility-id (merge facility {
      specializations: specializations
    }))

    (print {event: "specializations-updated", facility-id: facility-id})
    (ok true)))

;; Activate/deactivate facility
(define-public (set-facility-status (facility-id uint) (active bool))
  (let ((facility (unwrap! (map-get? facilities facility-id) ERR-FACILITY-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get owner facility)) ERR-NOT-AUTHORIZED)

    (map-set facilities facility-id (merge facility {
      active: active
    }))

    (print {event: "facility-status-changed", facility-id: facility-id, active: active})
    (ok true)))

;; Read-only Functions

;; Get facility details
(define-read-only (get-facility (facility-id uint))
  (map-get? facilities facility-id))

;; Get facility by owner
(define-read-only (get-facility-by-owner (owner principal))
  (match (map-get? facility-owners owner)
    facility-id (map-get? facilities facility-id)
    none))

;; Get facility rating details
(define-read-only (get-facility-rating (facility-id uint))
  (map-get? facility-ratings facility-id))

;; Check if facility has capacity
(define-read-only (has-capacity (facility-id uint) (required-capacity uint))
  (match (map-get? facilities facility-id)
    facility (and
      (get active facility)
      (>= (get available-capacity facility) required-capacity))
    false))

;; Get facilities with specialization
(define-read-only (has-specialization (facility-id uint) (specialization (string-ascii 30)))
  (match (map-get? facilities facility-id)
    facility (is-some (index-of (get specializations facility) specialization))
    false))

;; Get total number of facilities
(define-read-only (get-total-facilities)
  (var-get total-facilities))

;; Get next facility ID
(define-read-only (get-next-facility-id)
  (var-get next-facility-id))

;; Check if facility is active
(define-read-only (is-facility-active (facility-id uint))
  (match (map-get? facilities facility-id)
    facility (get active facility)
    false))

;; Get facility performance metrics
(define-read-only (get-facility-performance (facility-id uint))
  (match (map-get? facilities facility-id)
    facility (some {
      total-jobs: (get total-jobs facility),
      completed-jobs: (get completed-jobs facility),
      completion-rate: (if (> (get total-jobs facility) u0)
        (/ (* (get completed-jobs facility) u100) (get total-jobs facility))
        u0),
      rating: (get rating facility),
      capacity-utilization: (if (> (get capacity facility) u0)
        (/ (* (- (get capacity facility) (get available-capacity facility)) u100) (get capacity facility))
        u0)
    })
    none))
