require 'open_food_network/reports/report'

module OpenFoodNetwork::Reports
  class BulkCoopSupplierReport < Report
    header "Supplier", "Product", "Unit Size", "Variant", "Weight", "Sum Total", "Sum Max Total", "Units Required", "Remainder"

    organise do
      group { |li| li.variant.product.supplier }
      sort &:name

      organise do
        group { |li| li.variant.product }
        sort &:name

        summary_row do
          column { |lis| supplier_name(lis) }
          column { |lis| product_name(lis) }
          column { |lis| group_buy_unit_size_f(lis) }
          column { |lis| "" }
          column { |lis| "" }
          column { |lis| total_weight(lis) }
          column { |lis| total_max_quantity_weight(lis) }
          column { |lis| units_required(lis) }
          column { |lis| remainder(lis) }
        end

        organise do
          group { |li| li.variant }
          sort &:full_name
        end
      end
    end

    columns do
      column { |lis| supplier_name(lis) }
      column { |lis| product_name(lis) }
      column { |lis| group_buy_unit_size_f(lis) }
      column { |lis| lis.first.variant.full_name }
      column { |lis| lis.first.variant.weight || 0 }
      column { |lis| lis.sum(&:quantity) }
      column { |lis| lis.sum { |li| li.max_quantity || 0 } }
      column { |lis| '' }
      column { |lis| '' }
    end


    private

    class << self
      def supplier_name(lis)
        lis.first.variant.product.supplier.name
      end

      def product_name(lis)
        lis.first.variant.product.name
      end

      def group_buy_unit_size(lis)
        lis.first.variant.product.group_buy_unit_size || 0.0
      end

      def group_buy_unit_size_f(lis)
        if lis.first.variant.product.group_buy
          group_buy_unit_size(lis)
        else
          ""
        end
      end

      def total_weight(lis)
        lis.sum { |li| (li.quantity || 0)     * (li.variant.weight || 0) }
      end

      def total_max_quantity_weight(lis)
        lis.sum { |li| (li.max_quantity || 0) * (li.variant.weight || 0) }
      end

      def units_required(lis)
        if group_buy_unit_size(lis).zero?
          0
        else
          ( max_weight(lis) / group_buy_unit_size(lis) ).floor
        end
      end

      def remainder(lis)
        max_weight(lis) - (units_required(lis) * group_buy_unit_size(lis))
      end

      def max_weight(lis)
        max_weight = lis.sum do |li|
          max_quantity = [li.max_quantity || 0, li.quantity || 0].max
          max_quantity * (li.variant.weight || 0)
        end
      end
    end
  end
end
