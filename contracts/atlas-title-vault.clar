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
