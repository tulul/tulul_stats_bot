module TululStats
  class User < ActiveRecord::Base
    include HasTime

    searchkick

    ACCESSORS = [:message, :qting, :qted, :leliing, :slanging, :kbbiing, :getting, :blogging, :riya, :luing, :honest_asker, :keong_caller, :mentioning, :hashtagging, :linking, :replying, :replied, :forwarding, :forwarded, :ch_title, :ch_photo, :del_photo, :left_group, :join_group, :text, :audio, :document, :photo, :sticker, :video, :voice, :contact, :location].map(&:to_s)

    belongs_to :group, class_name: 'TululStats::Group', foreign_key: 'group_id'
    store :data, accessors: ACCESSORS, coder: JSON

    EXCEPTION = ['id', 'user_id', 'group_id', 'first_name', 'last_name', 'username', 'call_name', 'last_tulul_at', 'created_at', 'updated_at']

    ACCESSORS.each do |field|
      define_method(field) do
        super().to_i
      end

      define_method("#{field}=") do |par|
        super(par.to_i)
      end

      define_method("inc_#{field}") do
        TululStats::User.transaction(requires_new: true) do
          self.lock!
          self.send("#{field}=", self.send(field) + 1)
          self.save!
        end
      end
    end

    def self.get(user, group_id)
      user_id = user.peer_id rescue user.id
      res = self.find_or_create_by(user_id: user_id, group_id: group_id)

      res.first_name = user.first_name
      res.last_name = user.last_name
      res.username = user.username
      res.save if res.changed?

      res
    end

    def full_name
      res = self.first_name
      self.last_name && res += " #{self.last_name}"
      res
    end

    def username_or_full_name
      self.username && "@#{self.username}" || self.full_name
    end

    def merge_from_and_delete!(other_user)
      (self.class.column_names - EXCEPTION).each do |field|
        self.inc(field => other_user.send(field))
        TululStats::User.transaction(requires_new: true) do
          self.lock!
          self.send("#{field}=", self.send(field) + other_user.send(field)) if self.respond_to?("#{field}=")
          self.save!
        end
      end

      ['hour', 'day'].each do |time|
        other_user.send(time.pluralize).each do |t|
          "TululStats::#{time.titleize}".constantize.transaction(requires_new: true) do
            time = self.send(time.pluralize).find_or_create_by(time => t.send(time))
            time.count += t.count
            time.save!
          end
        end
      end

      other_user.destroy
    end
  end
end
