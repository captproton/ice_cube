module IceCube
  class HashParser

    attr_reader :hash

    def initialize(original_hash)
      @hash = original_hash
    end

    def to_schedule
      data = normalize_keys(hash)
      schedule = IceCube::Schedule.new parse_time(data[:start_time])
      apply_duration schedule, data
      apply_end_time schedule, data
      apply_rrules schedule, data
      apply_exrules schedule, data
      apply_rtimes schedule, data
      apply_extimes schedule, data
      yield schedule if block_given?
      schedule
    end

    private

    def normalize_keys(hash)
      data = IceCube::FlexibleHash.new(hash.dup)

      if (start_date = data.delete(:start_date))
				warn "IceCube: :start_date deprecated. (please use :start_time)"
        data[:start_time] = start_date
      end

      {:rdates => :rtimes, :exdates => :extimes}.each do |old_key, new_key|
        if (times = data.delete(old_key))
          warn "IceCube: :#{old_key} deprecated. (please use :#{new_key})"
          (data[new_key] ||= []).concat times
        end
      end

      data
    end

    def apply_duration(schedule, data)
      return unless data[:duration]
      schedule.duration = data[:duration].to_i
    end

    def apply_end_time(schedule, data)
      return unless data[:end_time]
      schedule.end_time = parse_time(data[:end_time])
    end

    def apply_rrules(schedule, data)
      return unless data[:rrules]
      data[:rrules].each do |h|
        schedule.rrule(IceCube::Rule.from_hash(h))
      end
    end

    def apply_exrules(schedule, data)
      return unless data[:exrules]
      warn "IceCube: :exrules deprecated. (This will be going away)"
      data[:exrules].each do |h|
        schedule.exrule(IceCube::Rule.from_hash(h))
      end
    end

    def apply_rtimes(schedule, data)
      return unless data[:rtimes]
      data[:rtimes].each do |t|
        schedule.add_recurrence_time TimeUtil.deserialize_time(t)
      end
    end

    def apply_extimes(schedule, data)
      return unless data[:extimes]
      data[:extimes].each do |t|
        schedule.add_exception_time TimeUtil.deserialize_time(t)
      end
    end

    def parse_time(time)
      TimeUtil.deserialize_time(time)
    end

  end
end
