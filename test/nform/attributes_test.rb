require 'test_helper'

describe NForm::Attributes do
  describe "basic cases" do
    class Example
      extend NForm::Attributes
      attribute :sample
      attribute :a_date, coerce: :input_to_date
      attribute :a_string, coerce: proc{|s| s.upcase }

      private
      def input_to_date(input)
        if input.nil?
          nil
        elsif input.is_a?(Date)
          input
        elsif input.is_a?(Hash)
          Date.new(input[:year],input[:month],input[:day])
        end
      end
    end
    it "should work with nil input" do
      a = Example.new
      assert_equal nil, a.sample
      assert_equal nil, a.a_date
      assert_equal nil, a.a_string
    end

    it "should work with string attrs" do
      a = Example.new 'sample' => 'foo'
      assert_equal 'foo', a.sample
    end

    it "should noop without coercion" do
      a = Example.new(sample: 1)
      assert_equal 1, a.sample
      a = Example.new(sample: "abc")
      assert_equal "abc", a.sample
    end

    it "should parse on coercion" do
      a = Example.new(a_date:{year:2015,month:1,day:1})
      assert a.a_date.is_a?(Date)
    end

    it "should return a hash of coerced values" do
      out = {sample: "Hello", a_date: Date.new(2015,1,1), a_string: nil}
      a = Example.new sample: "Hello", a_date: {year:2015,month:1,day:1}
      assert_equal out, a.to_hash
    end

    it "should call proc to coerce" do
      a = Example.new a_string: "hello"
      assert_equal "HELLO", a.a_string
    end
  end

  describe "required attributes" do
    class Example2
      extend NForm::Attributes
      attribute :an_optional
      attribute :a_required, required: true
    end

    it "should allow nil for optional attributes" do
      example = Example2.new(a_required: "foo")
      assert example
      assert example.an_optional == nil
    end

    it "should not allow nil for required attributes" do
      err = assert_raises(ArgumentError) do
        Example2.new(an_optional: "foo")
      end
      assert_match /(missing|required)/, err.message
    end
  end

  describe "default values" do
    class Example3
      extend NForm::Attributes
      attribute :a_normal
      attribute :a_default, default: "foo"
    end

    it "should have a default value" do
      example = Example3.new
      assert_equal "foo", example.a_default
    end

    it "should not have default unless set" do
      example = Example3.new
      assert_equal nil, example.a_normal
    end
  end

  describe "undefined attributes" do
    class DefOnly
      extend NForm::Attributes
      attribute :a_thing
    end
    class DefOnlyExplicit
      extend NForm::Attributes
      undefined_attributes :raise
      attribute :a_thing
    end
    class UndefOk
      extend NForm::Attributes
      undefined_attributes :ignore
      attribute :a_thing
    end

    it "should raise ArgumentError when unspecified attributes are given" do
      assert_raises(ArgumentError){ DefOnly.new(foo:1) }
    end

    it "should raise ArgumentError when unspecified attributes are given" do
      assert_raises(ArgumentError){ DefOnlyExplicit.new(foo:1) }
    end

    it "should ignore unspecified attributes when so configured" do
      ex = UndefOk.new(foo: 1)
      assert_equal nil, ex.a_thing
      assert_raises(NoMethodError) do
        ex.foo
      end
    end

  end
end
