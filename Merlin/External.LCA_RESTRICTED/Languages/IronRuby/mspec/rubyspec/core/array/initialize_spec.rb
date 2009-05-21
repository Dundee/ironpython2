require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "Array#initialize" do
  before :each do
    ScratchPad.clear
  end

  ruby_version_is "" ... "1.9" do
    it "is private" do
      [].private_methods.should include("initialize")
    end
  end

  ruby_version_is "1.9" do
    it "is private" do
      [].private_methods.should include(:initialize)
    end
  end

  it "is called on subclasses" do
    b = ArraySpecs::SubArray.new :size_or_array, :obj

    b.should == []
    ScratchPad.recorded.should == [:size_or_array, :obj]
  end

  it "preserves the object's identity even when changing its value" do
    a = [1, 2, 3]
    a.send(:initialize).should equal(a)
    a.should_not == [1, 2, 3]
  end

  it "raise an ArgumentError if passed 3 or more arguments" do
    lambda do
      [1, 2].send :initialize, 1, 'x', true
    end.should raise_error(ArgumentError)
    lambda do
      [1, 2].send(:initialize, 1, 'x', true) {}
    end.should raise_error(ArgumentError)
  end

  ruby_version_is '' ... '1.9' do
    it "raises a TypeError on frozen arrays even if the array would not be modified" do
      lambda do
        ArraySpecs.frozen_array.send :initialize
      end.should raise_error(TypeError)
      lambda do
        ArraySpecs.frozen_array.send :initialize, ArraySpecs.frozen_array
      end.should raise_error(TypeError)
    end
  end

  ruby_version_is '1.9' do
    it "raises a RuntimeError on frozen arrays even if the array would not be modified" do
      lambda do
        ArraySpecs.frozen_array.send :initialize
      end.should raise_error(RuntimeError)
      lambda do
        ArraySpecs.frozen_array.send :initialize, ArraySpecs.frozen_array
      end.should raise_error(RuntimeError)
    end
  end
end

describe "Array#initialize with no arguments" do
  it "makes the array empty" do
    [1, 2, 3].send(:initialize).should be_empty
  end

  it "does not use the given block" do
    lambda{ [1, 2, 3].send(:initialize) { raise } }.should_not raise_error
  end
end

describe "Array#initialize with (array)" do
  it "replaces self with the other array" do
    b = [4, 5, 6]
    [1, 2, 3].send(:initialize, b).should == b
  end

  it "does not use the given block" do
    lambda{ [1, 2, 3].send(:initialize) { raise } }.should_not raise_error
  end

  it "calls #to_ary to convert the value to an array" do
    a = mock("array")
    a.should_receive(:to_ary).and_return([1, 2])
    a.should_not_receive(:to_int)
    [].send(:initialize, a).should == [1, 2]
  end

  it "does not call #to_ary on instances of Array or subclasses of Array" do
    a = [1, 2]
    a.should_not_receive(:to_ary)
    [].send(:initialize, a).should == a
  end

  it "raises a TypeError if an Array type argument and a default object" do
    lambda { [].send(:initialize, [1, 2], 1) }.should raise_error(TypeError)
  end
end

describe "Array#initialize with (size, object=nil)" do
  it "sets the array to size and fills with the object" do
    a = []
    obj = [3]
    a.send(:initialize, 2, obj).should == [obj, obj]
    a[0].should equal(obj)
    a[1].should equal(obj)
  end

  it "sets the array to size and fills with nil when object is omitted" do
    [].send(:initialize, 3).should == [nil, nil, nil]
  end

  it "raises an ArgumentError if size is negative" do
    lambda { [].send(:initialize, -1, :a) }.should raise_error(ArgumentError)
    lambda { [].send(:initialize, -1) }.should raise_error(ArgumentError)
  end

  platform_is :wordsize => 32 do
    it "raises an ArgumentError if size is too large" do
      max_size = ArraySpecs.max_32bit_size
      lambda { [].send(:initialize, max_size + 1) }.should raise_error(ArgumentError)
    end
  end

  platform_is :wordsize => 64 do
    it "raises an ArgumentError if size is too large" do
      max_size = ArraySpecs.max_64bit_size
      lambda { [].send(:initialize, max_size + 1) }.should raise_error(ArgumentError)
    end
  end

  it "calls #to_int to convert the size argument to an Integer when object is given" do
    obj = mock('1')
    obj.should_receive(:to_int).and_return(1)
    [].send(:initialize, obj, :a).should == [:a]
  end

  it "calls #to_int to convert the size argument to an Integer when object is not given" do
    obj = mock('1')
    obj.should_receive(:to_int).and_return(1)
    [].send(:initialize, obj).should == [nil]
  end

  it "raises a TypeError if the size argument is not an Integer type" do
    obj = mock('nonnumeric')
    obj.stub!(:to_ary).and_return([1, 2])
    lambda{ [].send(:initialize, obj, :a) }.should raise_error(TypeError)
  end

  it "yields the index of the element and sets the element to the value of the block" do
    [].send(:initialize, 3) { |i| i.to_s }.should == ['0', '1', '2']
  end

  it "uses the block value instead of using the default value" do
    [].send(:initialize, 3, :obj) { |i| i.to_s }.should == ['0', '1', '2']
  end

  it "returns the value passed to break" do
    [].send(:initialize, 3) { break :a }.should == :a
  end

  it "sets the array to the values returned by the block before break is executed" do
    a = [1, 2, 3]
    a.send(:initialize, 3) do |i|
      break if i == 2
      i.to_s
    end

    a.should == ['0', '1']
  end
end