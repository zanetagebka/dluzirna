# Dlužírna - Debt Collection System

A Rails web application for managing and notifying customers about unpaid invoices in a construction materials business.

## Overview

Dlužírna is a professional debt collection system that enables systematic notification of customers about overdue payments. The application provides secure, tokenized access to debt information and automated email notifications.

## Features

- **Debt Management**: Create and track debt records with detailed information
- **Email Notifications**: Automated notifications to debtors with secure access links
- **Anonymous Access**: View debt information through masked URLs without registration
- **Customer Registration**: Optional registration for detailed debt access
- **Admin Panel**: Complete debt management interface for administrators
- **Responsive Design**: Bootstrap-based professional interface

## Technical Stack

- **Ruby**: 3.2+
- **Rails**: 7.1+
- **Database**: PostgreSQL
- **Background Jobs**: DelayedJob
- **Authentication**: Devise
- **Testing**: RSpec
- **UI Framework**: Bootstrap

## Setup

### Prerequisites

- Ruby 3.2 or higher
- PostgreSQL
- Bundler

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   bundle install
   ```

3. Setup database:
   ```bash
   rails db:create
   rails db:migrate
   rails db:seed
   ```

4. Start the application:
   ```bash
   rails server
   ```

5. Start background jobs:
   ```bash
   bundle exec rake jobs:work
   ```

## Testing

Run the test suite:
```bash
rspec
```

Run with coverage:
```bash
rspec --format documentation
```

## Code Quality

Run linter:
```bash
rubocop -A
```

## Development

The application follows Rails conventions with service layer architecture for business logic.

## Security

- Tokenized URLs for secure debt access
- Email verification for customer accounts  
- Admin-only access controls
- Input validation and sanitization

## License

Proprietary - Construction Materials Business
