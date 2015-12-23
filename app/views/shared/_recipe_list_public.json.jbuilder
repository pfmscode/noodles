json.recipes @recipes do |recipe|
  json.extract! recipe, :id, :title, :favorite, :user_id
  json.description_preview recipe.description.truncate(164)
  json.shared_url shared_path(recipe)
end