namespace :admin do
  desc "Create a new admin user"
  task create: :environment do
    email = ENV["email"]
    password = ENV["password"]

    if email.blank? || password.blank?
      puts "Usage: rake admin:create email=admin@firma.cz password=securepassword123"
      puts "Example: rake admin:create email=admin@firma.cz password=securepassword123"
      exit 1
    end

    begin
      admin = User.create!(
        email: email,
        password: password,
        password_confirmation: password,
        role: :admin,
        confirmed_at: Time.current # Skip email confirmation for admin
      )

      puts "✅ Admin user created successfully!"
      puts "   Email: #{admin.email}"
      puts "   Role: #{admin.role}"
      puts "   ID: #{admin.id}"
      puts ""
      puts "The admin can now log in at: http://localhost:3000/uzivatele/prihlaseni"

    rescue ActiveRecord::RecordInvalid => e
      puts "❌ Failed to create admin user:"
      e.record.errors.full_messages.each do |error|
        puts "   - #{error}"
      end
      exit 1
    rescue => e
      puts "❌ Unexpected error: #{e.message}"
      exit 1
    end
  end

  desc "List all admin users"
  task list: :environment do
    admins = User.admins.order(:created_at)

    if admins.empty?
      puts "No admin users found."
    else
      puts "Admin users:"
      puts "="*50
      admins.each do |admin|
        puts "ID: #{admin.id.to_s.ljust(3)} | Email: #{admin.email.ljust(30)} | Created: #{admin.created_at.strftime('%Y-%m-%d %H:%M')}"
      end
      puts "="*50
      puts "Total: #{admins.count} admin user(s)"
    end
  end

  desc "Delete an admin user by email"
  task delete: :environment do
    email = ENV["email"]

    if email.blank?
      puts "Usage: rake admin:delete email=admin@firma.cz"
      puts "Example: rake admin:delete email=admin@firma.cz"
      exit 1
    end

    admin = User.admins.find_by(email: email)

    if admin.nil?
      puts "❌ Admin user with email '#{email}' not found."
      exit 1
    end

    # Check if this admin has created any debts
    debt_count = admin.created_debts.count
    if debt_count > 0
      puts "⚠️  Warning: This admin has created #{debt_count} debt record(s)."
      print "Are you sure you want to delete this admin? (yes/no): "
      confirmation = STDIN.gets.chomp.downcase

      unless confirmation == "yes" || confirmation == "y"
        puts "Deletion cancelled."
        exit 0
      end
    end

    begin
      admin.destroy!
      puts "✅ Admin user '#{email}' deleted successfully."
    rescue => e
      puts "❌ Failed to delete admin user: #{e.message}"
      exit 1
    end
  end

  desc "Reset admin password"
  task reset_password: :environment do
    email = ENV["email"]
    new_password = ENV["password"]

    if email.blank? || new_password.blank?
      puts "Usage: rake admin:reset_password email=admin@firma.cz password=newsecurepassword123"
      puts "Example: rake admin:reset_password email=admin@firma.cz password=newsecurepassword123"
      exit 1
    end

    admin = User.admins.find_by(email: email)

    if admin.nil?
      puts "❌ Admin user with email '#{email}' not found."
      exit 1
    end

    begin
      admin.update!(
        password: new_password,
        password_confirmation: new_password
      )

      puts "✅ Password reset successfully for admin: #{admin.email}"
    rescue ActiveRecord::RecordInvalid => e
      puts "❌ Failed to reset password:"
      e.record.errors.full_messages.each do |error|
        puts "   - #{error}"
      end
      exit 1
    rescue => e
      puts "❌ Unexpected error: #{e.message}"
      exit 1
    end
  end

  desc "Show help for admin tasks"
  task :help do
    puts "Available admin tasks:"
    puts ""
    puts "  rake admin:create email=... password=...       - Create a new admin user"
    puts "  rake admin:list                                 - List all admin users"
    puts "  rake admin:delete email=...                     - Delete an admin user"
    puts "  rake admin:reset_password email=... password=... - Reset admin password"
    puts "  rake admin:help                                 - Show this help"
    puts ""
    puts "Examples:"
    puts "  rake admin:create email=admin@firma.cz password=securepass123"
    puts "  rake admin:list"
    puts "  rake admin:delete email=old_admin@firma.cz"
    puts "  rake admin:reset_password email=admin@firma.cz password=newpass123"
  end
end
