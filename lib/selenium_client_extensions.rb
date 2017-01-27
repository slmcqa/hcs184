module Selenium
  module Client
    module Extensions
      def get_css_count(css_locator)
        selector = JavascriptExpressionBuilder.new.quote_escaped css_locator.sub(/\Acss=/, '')
        script = <<-EOS
          var results = eval_css('#{selector}', window.document);
          results.length;
        EOS
        get_eval(script).to_i
      end
    end
  end
end