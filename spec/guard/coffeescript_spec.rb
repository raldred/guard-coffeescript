require 'spec_helper'

describe Guard::CoffeeScript do

  let(:guard) { Guard::CoffeeScript.new }

  let(:runner) { Guard::CoffeeScript::Runner }
  let(:inspector) { Guard::CoffeeScript::Inspector }

  let(:defaults) { Guard::CoffeeScript::DEFAULT_OPTIONS }

  before do
    inspector.stub(:clean)
    runner.stub(:run)
    runner.stub(:remove)
  end

  describe '#initialize' do
    context 'when no options are provided' do
      it 'sets a default :watchers option' do
        guard.watchers.should be_a Array
        guard.watchers.should be_empty
      end

      it 'sets a default :wrap option' do
        guard.options[:bare].should be_false
      end

      it 'sets a default :shallow option' do
        guard.options[:shallow].should be_false
      end

      it 'sets a default :hide_success option' do
        guard.options[:hide_success].should be_false
      end

      it 'sets a default :noop option' do
        guard.options[:noop].should be_false
      end

      it 'sets a default :all_on_start option' do
        guard.options[:all_on_start].should be_false
      end

      it 'sets the provided :source_maps option' do
        guard.options[:source_map].should be_false
      end

    end

    context 'with options besides the defaults' do
      let(:watcher) { Guard::Watcher.new('^x/.+\.(?:coffee|coffee\.md|litcoffee)$') }

      let(:guard) { Guard::CoffeeScript.new( { :output       => 'output_folder',
                                                   :bare         => true,
                                                   :shallow      => true,
                                                   :hide_success => true,
                                                   :all_on_start => true,
                                                   :noop         => true,
                                                   :source_map  => true,
                                                   :watchers     => [watcher]
      }) }

      it 'sets the provided :watchers option' do
        guard.watchers.should == [watcher]
      end

      it 'sets the provided :bare option' do
        guard.options[:bare].should be_true
      end

      it 'sets the provided :shallow option' do
        guard.options[:shallow].should be_true
      end

      it 'sets the provided :hide_success option' do
        guard.options[:hide_success].should be_true
      end

      it 'sets the provided :noop option' do
        guard.options[:noop].should be_true
      end

      it 'sets the provided :all_on_start option' do
        guard.options[:all_on_start].should be_true
      end

      it 'sets the provided :source_maps option' do
        guard.options[:source_map].should be_true
      end
    end

    context 'with a input option' do
      let(:guard) { Guard::CoffeeScript.new( { :input => 'app/coffeescripts' }) }

      it 'creates a watcher' do
        guard.should have(1).watchers
      end

      it 'watches all *.{coffee,coffee.md,litcoffee} files' do
        guard.watchers.first.pattern.should eql %r{^app/coffeescripts/(.+\.(?:coffee|coffee\.md|litcoffee))$}
      end

      context 'without an output option' do
        it 'sets the output directory to the input directory' do
          guard.options[:output].should eql 'app/coffeescripts'
        end
      end

      context 'with an output option' do
        let(:guard) { Guard::CoffeeScript.new( { :input  => 'app/coffeescripts',
                                                     :output => 'public/javascripts' }) }

        it 'keeps the output directory' do
          guard.options[:output].should eql 'public/javascripts'
        end
      end
    end
  end

  describe '#start' do
    it 'calls #run_all' do
      guard.should_not_receive(:run_all)
      guard.start
    end

    context 'with the :all_on_start option' do
      let(:guard) { Guard::CoffeeScript.new( :all_on_start => true) }

      it 'calls #run_all' do
        guard.should_receive(:run_all)
        guard.start
      end
    end
  end

  describe '#run_all' do
    let(:guard) { Guard::CoffeeScript.new( { :watchers => [Guard::Watcher.new('^x/.+\.(?:coffee|coffee\.md|litcoffee)$')] } ) }

    before do
      Dir.stub(:glob).and_return ['x/a.coffee', 'x/b.coffee', 'y/c.coffee', 'x/d.coffeeemd', 'x/e.litcoffee']
    end

    it 'runs the run_on_modifications with all watched CoffeeScripts' do
      guard.should_receive(:run_on_modifications).with(['x/a.coffee', 'x/b.coffee', 'x/e.litcoffee'])
      guard.run_all
    end
  end

  describe '#run_on_modifications' do
    it 'throws :task_has_failed when an error occurs' do
      inspector.should_receive(:clean).with(['a.coffee', 'b.coffee']).and_return ['a.coffee']
      runner.should_receive(:run).with(['a.coffee'], [], defaults).and_return [[], false]
      expect { guard.run_on_modifications(['a.coffee', 'b.coffee']) }.to throw_symbol :task_has_failed
    end

    it 'starts the Runner with the cleaned files' do
      inspector.should_receive(:clean).with(['a.coffee', 'b.coffee']).and_return ['a.coffee']
      runner.should_receive(:run).with(['a.coffee'], [], defaults).and_return [['a.js'], true]
      guard.run_on_modifications(['a.coffee', 'b.coffee'])
    end
  end

  describe '#run_on_removals' do
    it 'cleans the paths accepting missing files' do
      inspector.should_receive(:clean).with(['a.coffee', 'b.coffee'], { :missing_ok => true })
      guard.run_on_removals(['a.coffee', 'b.coffee'])
    end

    it 'removes the files' do
      inspector.should_receive(:clean).and_return ['a.coffee', 'b.coffee']
      runner.should_receive(:remove).with(['a.coffee', 'b.coffee'], guard.watchers, guard.options)
      guard.run_on_removals(['a.coffee', 'b.coffee'])
    end
  end
end
