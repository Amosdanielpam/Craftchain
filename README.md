# Craftchain - On-Chain Artisan Marketplace

A decentralized marketplace smart contract for verified handmade goods on the Stacks blockchain. Craftchain connects artisans directly with buyers, featuring reputation systems, verification processes, and transparent transactions.

## Features

- **Artisan Registration**: Creators can register their profiles with specialties and locations
- **Product Management**: Create, update, and manage handmade product listings
- **Secure Purchases**: STX-based transactions with automatic fee distribution
- **Verification System**: Platform-managed artisan verification badges
- **Rating & Reviews**: Comprehensive rating system for products and artisans
- **Order Tracking**: Full order lifecycle management from purchase to delivery
- **Platform Fees**: Configurable platform fee structure for marketplace sustainability

## Smart Contract Functions

### Artisan Management
- `register-artisan` - Register as a new artisan with profile details
- `verify-artisan` - Platform verification (admin only)
- `get-artisan` - Retrieve artisan information by ID
- `get-artisan-by-wallet` - Get artisan details by wallet address

### Product Management
- `create-product` - List a new handmade product
- `update-product-quantity` - Modify available inventory
- `toggle-product-status` - Activate/deactivate product listings
- `get-product` - Retrieve product details

### Purchasing System
- `purchase-product` - Buy products with STX payments
- `update-order-status` - Track order progress (artisan only)
- `get-order` - View order information

### Rating System
- `rate-product` - Rate and review purchased products (1-5 stars)
- `get-product-rating` - View specific product ratings
- `get-artisan-rating` - Calculate artisan's average rating

### Platform Administration
- `set-platform-fee` - Adjust marketplace fee percentage (admin only)

## Usage Examples

### Register as an Artisan
```clarity
(contract-call? .craftchain register-artisan "Alice Ceramics" "Pottery" "Portland, OR")
```

### Create a Product Listing
```clarity
(contract-call? .craftchain create-product 
  "Handmade Ceramic Bowl" 
  "Beautiful blue glazed ceramic bowl, dishwasher safe" 
  "Pottery" 
  u5000000 ; 50 STX in microSTX
  u10      ; 10 items available
  "QmHash123...")
```

### Purchase a Product
```clarity
(contract-call? .craftchain purchase-product u1 u2) ; Buy 2 units of product ID 1
```

### Rate a Product
```clarity
(contract-call? .craftchain rate-product u1 u5 "Excellent quality, fast shipping!")
```

## Error Codes

- `u100` - Not authorized
- `u101` - Already exists
- `u102` - Not found
- `u103` - Insufficient funds
- `u104` - Invalid amount
- `u105` - Already purchased
- `u106` - Cannot rate own product
- `u107` - Invalid rating (must be 1-5)
- `u108` - Product not purchased

## Getting Started

1. Deploy the contract to Stacks blockchain
2. Register as an artisan using `register-artisan`
3. Wait for platform verification (optional but recommended)
4. Create product listings with `create-product`
5. Buyers can purchase using `purchase-product`
6. Update order status as items are shipped/delivered
7. Buyers can rate products after purchase

## Platform Economics

- Platform fee: Default 2.5% (250 basis points)
- Fees are automatically deducted from purchases
- Artisans receive payment immediately upon purchase
- Platform fees support marketplace operations and development

## Security Features

- Wallet-based authentication
- Purchase verification for ratings
- Artisan-only product management
- Admin-controlled verification system
- Automatic fund escrow and distribution
