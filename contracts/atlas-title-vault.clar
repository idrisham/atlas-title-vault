;; atlas-title-vault-protocol
;; Decentralized asset provenance and ownership verification system

;; Core System Administrative Settings
(define-constant vault-administrator tx-sender)
(define-constant error-asset-missing (err u401))
(define-constant error-duplicate-asset-entry (err u402))
(define-constant error-invalid-asset-identifier (err u403))
(define-constant error-document-size-violation (err u404))
(define-constant error-access-denied (err u405))
(define-constant error-ownership-verification-failed (err u406))
(define-constant error-administrator-privilege-required (err u407))
(define-constant error-viewing-authorization-denied (err u408))
(define-constant error-metadata-format-violation (err u409))

;; Global Asset Registration Sequence Tracker
(define-data-var parcel-sequence-number uint u0)

;; Access Control Matrix for Asset Visibility Management
(define-map asset-access-control-matrix
  { parcel-reference: uint, authorized-entity: principal }
  { viewing-privilege: bool }
)

;; Primary Asset Registry Database Structure
(define-map quantum-asset-vault
  { parcel-reference: uint }
  {
    asset-identifier: (string-ascii 64),
    ownership-principal: principal,
    document-storage-size: uint,
    blockchain-registration-height: uint,
    asset-descriptive-metadata: (string-ascii 128),
    classification-metadata-array: (list 10 (string-ascii 32))
  }
)

;; Internal Asset Existence Verification Function
(define-private (asset-exists-in-vault? (parcel-reference uint))
  (is-some (map-get? quantum-asset-vault { parcel-reference: parcel-reference }))
)

;; Private Ownership Authentication Helper
(define-private (authenticate-asset-ownership (parcel-reference uint) (requesting-principal principal))
  (match (map-get? quantum-asset-vault { parcel-reference: parcel-reference })
    asset-record (is-eq (get ownership-principal asset-record) requesting-principal)
    false
  )
)

;; Document Storage Size Retrieval Utility
(define-private (retrieve-document-storage-allocation (parcel-reference uint))
  (default-to u0
    (get document-storage-size
      (map-get? quantum-asset-vault { parcel-reference: parcel-reference })
    )
  )
)

;; Metadata Tag Format Validation Function
(define-private (verify-metadata-tag-structure (classification-tag (string-ascii 32)))
  (and
    (> (len classification-tag) u0)
    (< (len classification-tag) u33)
  )
)

;; Complete Metadata Collection Validation System
(define-private (validate-metadata-collection-integrity (metadata-tags (list 10 (string-ascii 32))))
  (and
    (> (len metadata-tags) u0)
    (<= (len metadata-tags) u10)
    (is-eq (len (filter verify-metadata-tag-structure metadata-tags)) (len metadata-tags))
  )
)

;; Public Asset Registration Function with Comprehensive Validation
(define-public (establish-new-asset-registration 
  (asset-naming-identifier (string-ascii 64)) 
  (storage-allocation-bytes uint) 
  (descriptive-content (string-ascii 128)) 
  (classification-metadata (list 10 (string-ascii 32)))
)
  (let
    (
      (subsequent-parcel-id (+ (var-get parcel-sequence-number) u1))
    )
    ;; Comprehensive Input Validation Protocol
    (asserts! (> (len asset-naming-identifier) u0) error-invalid-asset-identifier)
    (asserts! (< (len asset-naming-identifier) u65) error-invalid-asset-identifier)
    (asserts! (> storage-allocation-bytes u0) error-document-size-violation)
    (asserts! (< storage-allocation-bytes u1000000000) error-document-size-violation)
    (asserts! (> (len descriptive-content) u0) error-invalid-asset-identifier)
    (asserts! (< (len descriptive-content) u129) error-invalid-asset-identifier)
    (asserts! (validate-metadata-collection-integrity classification-metadata) error-metadata-format-violation)

    ;; Asset Record Creation and Storage
    (map-insert quantum-asset-vault
      { parcel-reference: subsequent-parcel-id }
      {
        asset-identifier: asset-naming-identifier,
        ownership-principal: tx-sender,
        document-storage-size: storage-allocation-bytes,
        blockchain-registration-height: block-height,
        asset-descriptive-metadata: descriptive-content,
        classification-metadata-array: classification-metadata
      }
    )

    ;; Ownership Access Permission Initialization
    (map-insert asset-access-control-matrix
      { parcel-reference: subsequent-parcel-id, authorized-entity: tx-sender }
      { viewing-privilege: true }
    )

    ;; Registry Counter Advancement
    (var-set parcel-sequence-number subsequent-parcel-id)
    (ok subsequent-parcel-id)
  )
)

;; Comprehensive Asset Information Update Function
(define-public (modify-existing-asset-parameters 
  (parcel-reference uint) 
  (updated-identifier (string-ascii 64)) 
  (revised-storage-size uint) 
  (updated-descriptive-content (string-ascii 128)) 
  (revised-classification-metadata (list 10 (string-ascii 32)))
)
  (let
    (
      (existing-asset-record (unwrap! (map-get? quantum-asset-vault { parcel-reference: parcel-reference }) error-asset-missing))
    )
    ;; Asset Existence and Ownership Verification
    (asserts! (asset-exists-in-vault? parcel-reference) error-asset-missing)
    (asserts! (is-eq (get ownership-principal existing-asset-record) tx-sender) error-ownership-verification-failed)

    ;; Updated Information Validation Protocol
    (asserts! (> (len updated-identifier) u0) error-invalid-asset-identifier)
    (asserts! (< (len updated-identifier) u65) error-invalid-asset-identifier)
    (asserts! (> revised-storage-size u0) error-document-size-violation)
    (asserts! (< revised-storage-size u1000000000) error-document-size-violation)
    (asserts! (> (len updated-descriptive-content) u0) error-invalid-asset-identifier)
    (asserts! (< (len updated-descriptive-content) u129) error-invalid-asset-identifier)
    (asserts! (validate-metadata-collection-integrity revised-classification-metadata) error-metadata-format-violation)

    ;; Asset Registry Update Execution
    (map-set quantum-asset-vault
      { parcel-reference: parcel-reference }
      (merge existing-asset-record { 
        asset-identifier: updated-identifier, 
        document-storage-size: revised-storage-size, 
        asset-descriptive-metadata: updated-descriptive-content, 
        classification-metadata-array: revised-classification-metadata 
      })
    )
    (ok true)
  )
)

;; Asset Ownership Transfer Protocol
(define-public (execute-ownership-transfer (parcel-reference uint) (destination-principal principal))
  (let
    (
      (current-asset-record (unwrap! (map-get? quantum-asset-vault { parcel-reference: parcel-reference }) error-asset-missing))
    )
    ;; Asset Existence and Current Ownership Verification
    (asserts! (asset-exists-in-vault? parcel-reference) error-asset-missing)
    (asserts! (is-eq (get ownership-principal current-asset-record) tx-sender) error-ownership-verification-failed)

    ;; Ownership Record Update Execution
    (map-set quantum-asset-vault
      { parcel-reference: parcel-reference }
      (merge current-asset-record { ownership-principal: destination-principal })
    )
    (ok true)
  )
)

;; Asset Registry Removal Function
(define-public (eliminate-asset-from-vault (parcel-reference uint))
  (let
    (
      (target-asset-record (unwrap! (map-get? quantum-asset-vault { parcel-reference: parcel-reference }) error-asset-missing))
    )
    ;; Asset Existence and Ownership Verification Protocol
    (asserts! (asset-exists-in-vault? parcel-reference) error-asset-missing)
    (asserts! (is-eq (get ownership-principal target-asset-record) tx-sender) error-ownership-verification-failed)

    ;; Asset Record Elimination from Registry
    (map-delete quantum-asset-vault { parcel-reference: parcel-reference })
    (ok true)
  )
)

;; Supplementary Metadata Enhancement System
(define-public (append-classification-metadata (parcel-reference uint) (supplementary-metadata (list 10 (string-ascii 32))))
  (let
    (
      (current-asset-record (unwrap! (map-get? quantum-asset-vault { parcel-reference: parcel-reference }) error-asset-missing))
      (current-metadata-array (get classification-metadata-array current-asset-record))
      (merged-metadata-collection (unwrap! (as-max-len? (concat current-metadata-array supplementary-metadata) u10) error-metadata-format-violation))
    )
    ;; Asset Verification and Ownership Authentication
    (asserts! (asset-exists-in-vault? parcel-reference) error-asset-missing)
    (asserts! (is-eq (get ownership-principal current-asset-record) tx-sender) error-ownership-verification-failed)

    ;; Supplementary Metadata Validation
    (asserts! (validate-metadata-collection-integrity supplementary-metadata) error-metadata-format-violation)

    ;; Asset Record Update with Enhanced Metadata
    (map-set quantum-asset-vault
      { parcel-reference: parcel-reference }
      (merge current-asset-record { classification-metadata-array: merged-metadata-collection })
    )
    (ok merged-metadata-collection)
  )
)

;; Asset Description Modification Function
(define-public (revise-asset-descriptive-content (parcel-reference uint) (revised-description (string-ascii 128)))
  (let
    (
      (current-asset-record (unwrap! (map-get? quantum-asset-vault { parcel-reference: parcel-reference }) error-asset-missing))
    )
    ;; Asset Existence and Ownership Verification
    (asserts! (asset-exists-in-vault? parcel-reference) error-asset-missing)
    (asserts! (is-eq (get ownership-principal current-asset-record) tx-sender) error-ownership-verification-failed)

    ;; Description Content Validation
    (asserts! (> (len revised-description) u0) error-invalid-asset-identifier)
    (asserts! (< (len revised-description) u129) error-invalid-asset-identifier)

    ;; Description Update Execution
    (map-set quantum-asset-vault
      { parcel-reference: parcel-reference }
      (merge current-asset-record { asset-descriptive-metadata: revised-description })
    )
    (ok true)
  )
)

;; Emergency Asset Security Lockdown Protocol
(define-public (activate-emergency-asset-protection (parcel-reference uint))
  (let
    (
      (target-asset-record (unwrap! (map-get? quantum-asset-vault { parcel-reference: parcel-reference }) error-asset-missing))
      (emergency-security-tag "EMERGENCY-LOCK")
      (current-metadata-collection (get classification-metadata-array target-asset-record))
    )
    ;; Asset Verification and Administrative Authority Check
    (asserts! (asset-exists-in-vault? parcel-reference) error-asset-missing)
    (asserts! 
      (or 
        (is-eq tx-sender vault-administrator)
        (is-eq (get ownership-principal target-asset-record) tx-sender)
      ) 
      error-administrator-privilege-required
    )

    (ok true)
  )
)

;; Advanced Ownership Authentication and Verification System
(define-public (execute-ownership-authentication (parcel-reference uint) (claimed-owner-principal principal))
  (let
    (
      (asset-record (unwrap! (map-get? quantum-asset-vault { parcel-reference: parcel-reference }) error-asset-missing))
      (verified-owner (get ownership-principal asset-record))
      (registration-blockchain-height (get blockchain-registration-height asset-record))
      (access-authorization-status (default-to 
        false 
        (get viewing-privilege 
          (map-get? asset-access-control-matrix { parcel-reference: parcel-reference, authorized-entity: tx-sender })
        )
      ))
    )
    ;; Asset Existence and Viewing Authorization Verification
    (asserts! (asset-exists-in-vault? parcel-reference) error-asset-missing)
    (asserts! 
      (or 
        (is-eq tx-sender verified-owner)
        access-authorization-status
        (is-eq tx-sender vault-administrator)
      ) 
      error-access-denied
    )

    ;; Authentication Report Generation with Blockchain Verification
    (if (is-eq verified-owner claimed-owner-principal)
      ;; Successful Authentication Response
      (ok {
        authentication-valid: true,
        current-block: block-height,
        chain-age: (- block-height registration-blockchain-height),
        ownership-verified: true
      })
      ;; Ownership Mismatch Response
      (ok {
        authentication-valid: false,
        current-block: block-height,
        chain-age: (- block-height registration-blockchain-height),
        ownership-verified: false
      })
    )
  )
)

;; Access Permission Management System
(define-public (authorize-asset-viewing-access (parcel-reference uint) (authorized-viewer principal))
  (let
    (
      (asset-record (unwrap! (map-get? quantum-asset-vault { parcel-reference: parcel-reference }) error-asset-missing))
    )
    ;; Asset Verification and Ownership Authentication
    (asserts! (asset-exists-in-vault? parcel-reference) error-asset-missing)
    (asserts! (is-eq (get ownership-principal asset-record) tx-sender) error-ownership-verification-failed)

    (ok true)
  )
)

;; Viewing Permission Status Verification
(define-public (verify-asset-viewing-authorization (parcel-reference uint) (target-viewer principal))
  (let
    (
      (asset-record (unwrap! (map-get? quantum-asset-vault { parcel-reference: parcel-reference }) error-asset-missing))
      (current-access-status (default-to 
        false 
        (get viewing-privilege 
          (map-get? asset-access-control-matrix { parcel-reference: parcel-reference, authorized-entity: target-viewer })
        )
      ))
    )
    ;; Asset Existence Verification
    (asserts! (asset-exists-in-vault? parcel-reference) error-asset-missing)

    ;; Access Status Response
    (ok current-access-status)
  )
)

;; Access Permission Revocation System
(define-public (revoke-asset-viewing-access (parcel-reference uint) (target-viewer principal))
  (let
    (
      (asset-record (unwrap! (map-get? quantum-asset-vault { parcel-reference: parcel-reference }) error-asset-missing))
    )
    ;; Asset Verification and Authority Check
    (asserts! (asset-exists-in-vault? parcel-reference) error-asset-missing)
    (asserts! (is-eq (get ownership-principal asset-record) tx-sender) error-ownership-verification-failed)
    (asserts! (not (is-eq target-viewer tx-sender)) error-administrator-privilege-required)

    ;; Access Permission Removal
    (map-delete asset-access-control-matrix { parcel-reference: parcel-reference, authorized-entity: target-viewer })
    (ok true)
  )
)

;; Total Registry Count Retrieval Function
(define-read-only (retrieve-total-registered-assets)
  (var-get parcel-sequence-number)
)

;; Comprehensive Asset Information Retrieval System
(define-read-only (retrieve-asset-registry-information (parcel-reference uint))
  (let
    (
      (asset-record (unwrap! (map-get? quantum-asset-vault { parcel-reference: parcel-reference }) error-asset-missing))
      (verified-owner (get ownership-principal asset-record))
      (viewing-authorization-status (default-to 
        false 
        (get viewing-privilege 
          (map-get? asset-access-control-matrix { parcel-reference: parcel-reference, authorized-entity: tx-sender })
        )
      ))
    )
    ;; Asset Existence and Viewing Authorization Verification
    (asserts! (asset-exists-in-vault? parcel-reference) error-asset-missing)
    (asserts! 
      (or 
        (is-eq tx-sender verified-owner)
        viewing-authorization-status
        (is-eq tx-sender vault-administrator)
      ) 
      error-access-denied
    )

    ;; Asset Information Response
    (ok asset-record)
  )
)

