# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Seeding database..."

# Create Admin Users
puts "Creating admin users..."
admin1 = User.find_or_create_by!(email: "admin@dluzirna.cz") do |user|
  user.password = "password123"
  user.password_confirmation = "password123"
  user.role = :admin
  user.confirmed_at = Time.current
end

admin2 = User.find_or_create_by!(email: "spravce@dluzirna.cz") do |user|
  user.password = "password123"
  user.password_confirmation = "password123"
  user.role = :admin
  user.confirmed_at = Time.current
end

# Create Customer Users (some confirmed, some not)
puts "Creating customer users..."
customer1 = User.find_or_create_by!(email: "jan.novak@email.cz") do |user|
  user.password = "password123"
  user.password_confirmation = "password123"
  user.role = :customer
  user.confirmed_at = Time.current
end

customer2 = User.find_or_create_by!(email: "marie.svobodova@firma.cz") do |user|
  user.password = "password123"
  user.password_confirmation = "password123"
  user.role = :customer
  user.confirmed_at = Time.current
end

# Unconfirmed customer
customer3 = User.find_or_create_by!(email: "petr.dvorak@stavba.cz") do |user|
  user.password = "password123"
  user.password_confirmation = "password123"
  user.role = :customer
  # Not confirmed yet
end

puts "Creating debt records..."

# Current debts (various statuses)
debt1 = Debt.find_or_create_by!(customer_email: "jan.novak@email.cz") do |debt|
  debt.amount = 15_450.50
  debt.due_date = 1.month.from_now
  debt.description = "Faktura č. 2024-001 - Cement Portland 42.5 R (20 pytlů), štěrk frakce 16-32mm (5m³)"
  debt.status = :registered
  debt.customer_user = customer1
  debt.notified_at = 2.days.ago
  debt.viewed_at = 1.day.ago
  debt.token = SecureRandom.urlsafe_base64(32)
end

Debt.find_or_create_by!(customer_email: "marie.svobodova@firma.cz") do |debt|
  debt.amount = 8_750.00
  debt.due_date = 2.weeks.from_now
  debt.description = "Faktura č. 2024-002 - Ocelová výztuž fi 12mm (500kg), betonová směs C 25/30 (3m³)"
  debt.status = :viewed
  debt.customer_user = customer2
  debt.notified_at = 3.days.ago
  debt.viewed_at = 2.days.ago
  debt.token = SecureRandom.urlsafe_base64(32)
end

# Overdue debts
Debt.find_or_create_by!(customer_email: "stavebni.firma@example.com") do |debt|
  debt.amount = 32_100.75
  debt.due_date = 1.month.ago
  debt.description = "Faktura č. 2024-003 - Železobetonové panely (10ks), hydroizolace SBS modifikovaná (150m²)"
  debt.status = :notified
  debt.notified_at = 1.week.ago
  debt.token = SecureRandom.urlsafe_base64(32)
end

Debt.find_or_create_by!(customer_email: "petr.dvorak@stavba.cz") do |debt|
  debt.amount = 4_850.00
  debt.due_date = 2.weeks.ago
  debt.description = "Faktura č. 2024-004 - Cihly plněné CDm 17.5 P15 (1000ks), malta vápenocementová (2m³)"
  debt.status = :viewed
  debt.customer_user = customer3
  debt.notified_at = 10.days.ago
  debt.viewed_at = 8.days.ago
  debt.token = SecureRandom.urlsafe_base64(32)
end

# Recent debts (still pending)
Debt.find_or_create_by!(customer_email: "nova.stavba@email.cz") do |debt|
  debt.amount = 12_300.25
  debt.due_date = 3.weeks.from_now
  debt.description = "Faktura č. 2024-005 - Pražec betonový železniční (50ks), kamenná dlažba žulová (25m²)"
  debt.status = :pending
  debt.token = SecureRandom.urlsafe_base64(32)
end

Debt.find_or_create_by!(customer_email: "rekonstrukce.s.r.o@firma.cz") do |debt|
  debt.amount = 28_950.00
  debt.due_date = 1.week.from_now
  debt.description = "Faktura č. 2024-006 - Tepelná izolace EPS 100 tl. 100mm (200m²), lepící malta na polystyren (30 pytlů)"
  debt.status = :notified
  debt.notified_at = 1.day.ago
  debt.token = SecureRandom.urlsafe_base64(32)
end

# Large debt
Debt.find_or_create_by!(customer_email: "velky.zakaznik@stavby.cz") do |debt|
  debt.amount = 85_670.50
  debt.due_date = 10.days.ago
  debt.description = "Faktura č. 2024-007 - Kompletní dodávka pro RD: Beton C 30/37 (15m³), ocel betonářská (2000kg), cihly Porotherm (paleta), střešní tašky Bramac (200m²)"
  debt.status = :viewed
  debt.notified_at = 1.week.ago
  debt.viewed_at = 5.days.ago
  debt.token = SecureRandom.urlsafe_base64(32)
end

# Resolved debt (for statistics)
Debt.find_or_create_by!(customer_email: "rychle.platby@email.cz") do |debt|
  debt.amount = 6_780.00
  debt.due_date = 1.week.ago
  debt.description = "Faktura č. 2024-008 - Záhradní obrubníky betonové (100mb), píssek říční praný (2m³)"
  debt.status = :resolved
  debt.notified_at = 2.weeks.ago
  debt.viewed_at = 10.days.ago
  debt.token = SecureRandom.urlsafe_base64(32)
end

# Small amounts
Debt.find_or_create_by!(customer_email: "drobny.zakaznik@email.cz") do |debt|
  debt.amount = 1_250.00
  debt.due_date = 5.days.from_now
  debt.description = "Faktura č. 2024-009 - Penetrační nátěr (5L), malířský váleček s náhradou (3ks)"
  debt.status = :pending
  debt.token = SecureRandom.urlsafe_base64(32)
end

Debt.find_or_create_by!(customer_email: "oprava.domu@email.cz") do |debt|
  debt.amount = 890.50
  debt.due_date = 3.days.ago
  debt.description = "Faktura č. 2024-010 - Sádrokartonové desky GKB 12.5mm (10ks), spárovací hmota (2kg)"
  debt.status = :notified
  debt.notified_at = 2.days.ago
  debt.token = SecureRandom.urlsafe_base64(32)
end

puts "Seeding completed!"
puts ""
puts "Summary:"
puts "  Admin users: #{User.admins.count}"
puts "  Customer users: #{User.customers.count}"
puts "  Total debts: #{Debt.count}"
puts "  Total debt amount: #{Debt.sum(:amount)} Kč"
puts ""
puts "Login credentials:"
puts "  Admin: admin@dluzirna.cz / password123"
puts "  Admin: spravce@dluzirna.cz / password123"
puts "  Customer: jan.novak@email.cz / password123"
puts "  Customer: marie.svobodova@firma.cz / password123"
puts ""
puts "Debt status distribution:"
Debt.group(:status).count.each do |status, count|
  puts "  #{status.humanize}: #{count}"
end
