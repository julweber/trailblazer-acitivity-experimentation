require 'pp'
require 'byebug'
require 'trailblazer-activity'

class Song
end

class MyTask1
  def self.call( signal, options, flow_options, *args )
    puts "#{self}#call"

    options['model'] = Song.new
    if options['number'].nil?
      options['number'] = 1
    else
      options['number'] = options['number'] + 1
    end
    puts "Number: #{options['number']}"
    options['added_1'] = 'Test1'

    if options[:flow_left] == true
      return [ Trailblazer::Circuit::Left, options, flow_options, *args ]
    end

    [ Trailblazer::Circuit::Right, options, flow_options, *args ]
  end

  # def self.outputs
  #   byebug
  #   {
  #     Circuit::End.new(:success) => {
  #       role: :success
  #     },
  #     Circuit::End.new(:fail) => {
  #       role: :failure
  #     }
  #   }
  # end
end

class MyTask2
  def self.call( signal, options, flow_options, *args )
    puts "#{self}#call"

    if options['number'].nil?
      options['number'] = 1
    else
      options['number'] = options['number'] + 2
    end
    options['added_2'] = 'Test2'
    puts "Number: #{options['number']}"

    [ Trailblazer::Circuit::Right, options, flow_options, *args ]
  end
end

class MyTask3
  def self.call( signal, options, flow_options, *args )
    puts "#{self}#call"

    if options['number'].nil?
      options['number'] = 1
    else
      options['number'] = options['number'] * 10
    end
    options['added_3'] = 'Test3'
    puts "Number: #{options['number']}"

    [ Trailblazer::Circuit::Right, options, flow_options, *args ]
  end
end

class Test
  def self.create_activity
    ::Trailblazer::Activity.from_hash do |start, _end|
      {
        start => { Trailblazer::Circuit::Right => MyTask1 },
        MyTask1 => {
          Trailblazer::Circuit::Right => MyTask2,
          Trailblazer::Circuit::Left => MyTask3
        },
        MyTask2 => { Trailblazer::Circuit::Right => _end },
        MyTask3 => { Trailblazer::Circuit::Right => MyTask2 }
        #,
        # MyTask3 => { Trailblazer::Circuit::Right => _end }
      }
    end
  end
end

puts 'flow_left: false'
activity = Test.create_activity
my_options = { flow_left: false }
last_signal, options, flow_options, _ = activity.( nil, my_options, {} )
pp last_signal
pp options
pp flow_options

puts "-"*20

puts 'flow_left: true'
activity = Test.create_activity
my_options = { flow_left: true }
last_signal, options, flow_options, _ = activity.( nil, my_options, {} )
pp last_signal
pp options
pp flow_options
