namespace :showcase do
  task reset: :environment do
    org = Organization.find_by(subdomain: "showcase")
    org.members.each { |m| m.transactions.delete_all }
  end
end
