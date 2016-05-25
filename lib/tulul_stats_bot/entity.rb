module TululStatsBot
  class Entity
    include Mongoid::Document

    field :type, type: String
    field :content, type: String

    index({ type: 1 })

    belongs_to :group, class_name: 'TululStatsBot::Group', index: true

    ENTITY_QUERY = ['mention', 'hashtag', 'url']

    store_in collection: 'tulul_stats_entities'

    def self.add_new(content, type, group_id)
      self.create(
        type: type,
        content: content,
        group_id: group_id
      )
    end

    def content
      if self.type == 'url'
        return self[:content].match(/^(?:https?:\/\/)?(?:[^@\/\n]+@)?(?:www\.)?([^:\/\n]+)/).captures[0]
      end
      self[:content]
    end
  end
end
