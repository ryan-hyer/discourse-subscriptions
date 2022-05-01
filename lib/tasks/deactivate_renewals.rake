# frozen_string_literal: true

require 'stripe'
require 'highline/import'

desc 'Turn off auto-renew for Discourse subscriptions'
task 'subscriptions:deactivate_renewals' => :environment do
  setup_api
  products = get_stripe_products
  stripe_products_to_deactivate = []

  products.each do |product|
    confirm_cancel = ask("Do you wish to cancel auto-renew for product #{product[:name]} (id: #{product[:id]}): (y/N)")
    next if confirm_cancel.downcase != 'y'
    stripe_products_to_deactivate << product
  end

  deactivate_subscriptions(stripe_products_to_deactivate)
end

def get_stripe_products(starting_after: nil)
  puts 'Getting products from Stripe API'

  all_products = []

  loop do
    products = Stripe::Product.list({ type: 'service', starting_after: starting_after, active: true })
    all_products += products[:data]
    break if products[:has_more] == false
    starting_after = products[:data].last["id"]
  end

  all_products
end

def get_stripe_subscriptions(starting_after: nil)
  puts 'Getting Subscriptions from Stripe API'

  all_subscriptions = []

  loop do
    subscriptions = Stripe::Subscription.list({ starting_after: starting_after, status: 'active' })
    all_subscriptions += subscriptions[:data]
    break if subscriptions[:has_more] == false
    starting_after = subscriptions[:data].last["id"]
  end

  all_subscriptions
end

def deactivate_subscriptions(products)
  puts 'Deactivating subscriptions'
  product_ids = products.pluck(:id)

  subscriptions = get_stripe_subscriptions
  
  subscriptions_for_products = subscriptions.select { |sub| product_ids.include?(sub[:items][:data][0][:price][:product]) }
  puts "Total Subscriptions matching Products to Deactivate: #{subscriptions_for_products.length.to_s}"

  subscriptions_for_products.each do |subscription|
    subscription_id = subscription[:id]

    updated_subsciption = Stripe::Subscription.update(subscription_id, { cancel_at_period_end: true })
    puts "Stripe Subscription: #{updated_subsciption[:id]} UPDATED"

  end
end

private

def setup_api
  api_key = SiteSetting.discourse_subscriptions_secret_key || ask('Input Stripe secret key')
  Stripe.api_key = api_key
end
