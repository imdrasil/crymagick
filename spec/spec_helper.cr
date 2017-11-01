require "../src/crymagick"
require "minitest/autorun"
require "./support/helper"

module Minitest
  class Test
    include Helper
    extend Helper

    macro expect_to_change(block, **opts)
      %old = {{block.id}}.call
      {{yield}}
      %new = {{block.id}}.call
      {% if opts[:to] != nil %}
        expect(%new).must_equal({{opts[:to]}})
      {% else %}
        expect(%old).wont_equal(%new)
      {% end %}
    end

    macro expect_not_to_change(block)
      %old = {{block.id}}.call
      {{yield}}
      %new = {{block.id}}.call
      expect(%old).must_equal(%new)
    end

    macro expect_be_a(obj, klass)
      expect({{obj}}.class).must_equal({{klass}})
    end
  end
end
