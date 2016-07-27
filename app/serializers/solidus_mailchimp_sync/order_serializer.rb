require 'json'

module SolidusMailchimpSync
  # Serializes to Mailchimp Cart or Order, depending on state.
  class OrderSerializer
    attr_reader :order

    def initialize(order)
      @order = order
      unless order.persisted?
        raise ArgumentError, "Can't serialize a non-saved order: #{order}"
      end
    end

    def as_json
      hash = {
        id: order.id.to_s,
        customer: {
          id: UserSynchronizer.customer_id(order.user)
        },
        currency_code: order.currency,
        order_total: order.total.to_f,
        tax_total: order.tax_total.to_f,
        lines: line_items
      }

      url = cart_url
      hash["checkout_url"] = url if url

      hash
    end

    # Override in custom serializer for custom front-end url
    def cart_url
      # Mailchimp does not take URLs for orders, just carts
      if order_is_cart?
        if Rails.application.routes.default_url_options[:host] && Spree::Core::Engine.routes.url_helpers.respond_to?(:cart_url)
          Spree::Core::Engine.routes.url_helpers.cart_url(host: Rails.application.routes.default_url_options[:host])
        end
      end
    end

    def order_is_cart?
      order.completed_at.blank?
    end

    def to_json
      JSON.dump(as_json)
    end

    def line_items
      order.line_items.collect do |line_item|
        LineItemSerializer.new(line_item).as_json
      end
    end
  end
end