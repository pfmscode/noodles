class RecipeListSerializer < BaseSerializer
  cache key: 'recipe_list'

  attributes :id, :title, :description, :path, :public_path,
             :favorite, :notes, :photo, :web, :collections, :last_cooked_at

  def notes
    object.notes.present?
  end

  def photo
    object.imaged?
  end

  def collections
    object.collections.present?
  end

  def web
    object.from_web?
  end

  def path
    recipe_path object
  end

  def public_path
    share_path object.shared_id
  end
end
