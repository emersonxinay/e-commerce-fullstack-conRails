class WebhooksController < ApplicationController
  skip_forgery_protection

  def stripe
    stripe_secret_key = Rails.application.credentials.dig(:stripe, :secret_key)
    Stripe.api_key = stripe_secret_key
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    endpoint_secret = Rails.application.credentials.dig(:stripe, :webhook_secret) 
    event = nil

    begin
      event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
    rescue JSON::ParserError => e
      status 400
      return
    rescue Stripe::SignatureVerificationError => e
      puts "Webhook signature verification failed."
      status 400
      return
    end

    case event.type 
    when 'checkout.session.completed'
      session = event.data.object 
      shipping_details = session["shipping_details"]
      puts "Session: #{session}"
      if shipping_details
        address = "#{shipping_details['address']['line1']} #{shipping_details['address']['city']}, #{shipping_details['address']['state']} #{shipping_details["address"]["postal_code"]}"
        address = address.force_encoding("UTF-8").encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
      else
        address = ""
      end 
      order = Order.create!(customer_email: session["customer_details"]["email"], total: session["amount_total"], address: address, fulfilled: false)
      full_session = Stripe::Checkout::Session.retrieve({
        id: session.id,
        expand: ['line_items']
      })
      line_items = full_session.line_items
      line_items["data"].each do |item|
        product = Stripe::Product.retrieve(item["price"]["product"])
        product_id = product["metadata"]["product_id"].to_i
        quantity = item["quantity"].to_i
        size = item["metadata"]["size"]
      
        # Aplicar sugerencias para forzar la codificación y manejar caracteres no válidos
        size = size.to_s.force_encoding("UTF-8").encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
      
        OrderProduct.create!(order: order, product_id: product_id, quantity: item["quantity"], size: product["metadata"]["size"])
        Stock.find(product["metadata"]["product_stock_id"]).decrement!(:amount, item["quantity"])
      end
    else
      puts "Unhandled event type: #{event.type}" 
    end

    render json: { message: 'success' }
  end
end