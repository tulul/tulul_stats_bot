module TululStats
  class User
    include Mongoid::Document

    field :user_id,           type: Integer
    field :first_name,        type: String
    field :last_name,         type: String
    field :username,          type: String

    field :message,           type: Integer, default: 0
    field :qting,             type: Integer, default: 0
    field :qted,              type: Integer, default: 0
    field :replying,          type: Integer, default: 0
    field :replied,           type: Integer, default: 0
    field :forwarding,        type: Integer, default: 0
    field :forwarded,         type: Integer, default: 0
    field :ch_title,          type: Integer, default: 0
    field :ch_photo,          type: Integer, default: 0
    field :del_photo,         type: Integer, default: 0
    field :left_group,        type: Integer, default: 0
    field :join_group,        type: Integer, default: 0

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

    belongs_to :group, class_name: 'TululStats::Group', index: true

    EXCEPTION = ['_id', 'user_id', 'group_id', 'first_name', 'last_name', 'username']

    self.fields.except(EXCEPTION).keys.each do |field|
      define_method("inc_#{field}") do
        self.inc("#{field}" => 1)
      end
    end

    def self.get(user, group_id)
      res = self.find_or_create_by(user_id: user.id, group_id: group_id)

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
  end
end