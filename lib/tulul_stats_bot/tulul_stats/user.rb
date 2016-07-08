module TululStats
  class User
    include Mongoid::Document
    include HasTime

    field :user_id,           type: Integer
    field :first_name,        type: String
    field :last_name,         type: String
    field :username,          type: String

    field :message,           type: Integer, default: 0
    field :qting,             type: Integer, default: 0
    field :qted,              type: Integer, default: 0
    field :leliing,           type: Integer, default: 0
    field :slanging,          type: Integer, default: 0
    field :kbbiing,           type: Integer, default: 0
    field :getting,           type: Integer, default: 0
    field :blogging,          type: Integer, default: 0
    field :luing,             type: Integer, default: 0
    field :latecomer,         type: Integer, default: 0
    field :honest_asker,      type: Integer, default: 0
    field :keong_caller,      type: Integer, default: 0
    field :mentioning,        type: Integer, default: 0
    field :hashtagging,       type: Integer, default: 0
    field :linking,           type: Integer, default: 0
    field :replying,          type: Integer, default: 0
    field :replied,           type: Integer, default: 0
    field :forwarding,        type: Integer, default: 0
    field :forwarded,         type: Integer, default: 0
    field :ch_title,          type: Integer, default: 0
    field :ch_photo,          type: Integer, default: 0
    field :del_photo,         type: Integer, default: 0
    field :left_group,        type: Integer, default: 0
    field :join_group,        type: Integer, default: 0
    field :last_tulul_at,     type: DateTime

    field :text,              type: Integer, default: 0
    field :audio,             type: Integer, default: 0
    field :document,          type: Integer, default: 0
    field :photo,             type: Integer, default: 0
    field :sticker,           type: Integer, default: 0
    field :video,             type: Integer, default: 0
    field :voice,             type: Integer, default: 0
    field :contact,           type: Integer, default: 0
    field :location,          type: Integer, default: 0

    index({ user_id: 1, group_id: 1 }, { unique: true })
    index({ username: 1, group_id: 1 })

    belongs_to :group, class_name: 'TululStats::Group', index: true

    EXCEPTION = ['_id', 'user_id', 'group_id', 'first_name', 'last_name', 'username', 'last_tulul_at']

    self.fields.keys.reject{ |field| EXCEPTION.include?(field) }.each do |field|
      define_method("inc_#{field}") do
        self.inc("#{field}" => 1)
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
  end
end
