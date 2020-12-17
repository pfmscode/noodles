# Provide all services related to scraping the web for a recipe.
module ScrapingHelper
  include RecipesHelper

  def master_scrape(url)
    begin
      data = safely { JSON.load(open("https://escargot-r9tc75z4t.now.sh/api/scrape?url=#{url}")) }
    rescue OpenURI::HTTPError
    end
    if !data
      page = safely { Mechanize.new.get(url).content }
      data = Hangry.parse(page).to_h
      data = process_recipe_page(url, page, data)
      data = create_recipe_item data
    end
    data
  end

  # Process recipe pages
  def process_recipe_page(url, page, data)
    host = find_domain(url).to_s
    doc = Nokogiri::HTML::DocumentFragment.parse(page)
    # if host.match? 'nytimes.com'
      # data = process_nyt_page!(data, doc)
    if host.match? 'epicurious.com'
      data = process_epicurious_page!(data, doc)
    elsif host.match? 'allrecipes.com'
      data = process_allrecipes_page!(data, doc)
    elsif host.match? 'foodandwine.com'
      data = process_fw_page!(data, doc)
    elsif host.match? 'bonappetit.com'
      data = process_ba_page!(data, doc)
    elsif host.match? 'marthastewart.com'
      data.instructions = doc.css('.directions-list .directions-item').text
    elsif host.match? 'driscolls.com'
      data.instructions = doc.css('#recipe-content #instructions').text
    end
    if data.to_h.values.reject(&:blank?).empty?
      data = process_schema_for doc
    elsif data.instructions.to_s.match(/\n/).blank?
      data = process_blog_page! data, doc
    end
    data
  end

  def process_schema_for(doc)
    meta = doc.css('script[type="application/ld+json"]').text.squish
    return {} unless meta
    values = JSON.parse(meta)
    {
      name: values['name'],
      description: values['description']&.squish,
      ingredients: values['recipeIngredient'],
      instructions: values['recipeInstructions'],
      yield: values['recipeYield'].to_s.remove('Makes '),
      author: values['author']['name']
    }
  end

  # Fixes for NYT Cooking
  def process_nyt_page!(data, doc)
    s = [
      '[itemprop=description] p:first-of-type',
      '.recipe-ingredients li',
      '.recipe-steps li',
      '.recipe-subhead span[itemprop=author]',
      'ul.recipe-notes li'
    ]
    data.description = doc.css(s[0])&.text
    data.ingredients = doc.css(s[1])&.to_a&.map(&:text)
    data.instructions = doc.css(s[2])&.to_a&.map(&:text)
    data.author = doc.search(s[3])&.text
    data.notes = doc.css(s[4])&.to_a&.map(&:text).join("\n")
    data
  end

  # Fixes for Epicurious
  def process_epicurious_page!(data, doc)
    data.name = doc.css('h1[itemprop=name]').text
    data.description = doc.css('.dek[itemprop=description]').text
    data.ingredients = []
    data.instructions = []
    doc.css('.ingredients-info [itemprop=ingredients]').each do |n|
      data.ingredients.push n.text
    end
    n = ':not(#chefNotes)'
    i = "#{inst} li#{n}, #{inst} > p#{n}"
    data.instructions = doc.css(i).text.split(/\n/).map(&:strip).flatten.uniq.join("\n")
    data.yield = doc.css('[itemprop=recipeYield]').text
    data
  end

  # Fixes for Allrecipes
  def process_allrecipes_page!(data, doc)
    data.name = doc.css('.recipe-summary h1[itemprop=name]')&.text
    data.ingredients = doc.css('li span[itemprop="recipeIngredient"]')&.map(&:text)
    data.yield = doc.css('meta[itemprop="recipeYield"]')&.attr('content')&.text
    data.yield += ' servings' if data.yield.present?
    data
  end

  # Fixes for Food & Wine
  def process_fw_page!(data, doc)
    data.name = doc.css('h1')[0].text
    data.description = doc.css('.recipe-summary')&.text
    data.ingredients = doc.css('.ingredients li').to_a.map(&:text)
    data.instructions = doc.css("#{inst} p:last-child").to_a.map(&:text)
    data.yield = doc.css('.recipe-meta-item-body:last-of-type')&.text
    data
  end

  # Fixes for Bon Appetit
  def process_ba_page!(data, doc)
    data.name = doc.css('h1[itemprop=name]').text
    data.description = doc.css('.dek--basically').text
    data.ingredients = doc.css('.ingredients li').to_a.map(&:text)
    data.instructions = doc.css('.steps .step').to_a.map(&:text)
    data.author = doc.css('.contributor-recipe-author .contributor-name')&.text
    data.yield = doc.css('.recipe__header__servings')&.text
    data
  end

  # Support some sites (mainly blogs)
  def process_blog_page!(data, doc)
    data.instructions = doc.css(inst).to_a.map(&:text)
    if data&.ingredients.empty?
      s = '.wprm-recipe-ingredient-group li[itemprop=recipeIngredient]'
      data.ingredients = doc.css(s).to_a.map(&:text)
    end
    data
  end

  # Basic scaffolding for recipe item
  def create_recipe_item(data)
    {
      title: data[:name].to_s.squish.truncate(255),
      description: data[:description].to_s.squish,
      ingredients: data[:ingredients],
      instructions: data[:instructions],
      serves: data[:yield].to_s.capitalize.remove('Servings:',).strip
    }
  end

  # Create a Recipe with provided data
  def create_recipe(data, url_source)
    data['user_id'] = current_user.id
    data['img'] = open(data['photo']) if data['photo']
    data.delete('photo')
    data['ingredients'] = process_recipe_ingredients data[:ingredients]
    data['instructions'] = process_recipe_instructions data[:instructions]
    data['source'] = url_source
      # 'favorite': false,
      # img: data['photo'] ? open(data['photo']) : nil
    # ).delete(:photo)
    # puts attrs
    Recipe.create(data)
    # title: recipe_data[:title],
    # description: recipe_data[:description],
    # ingredients: recipe_data[:ingredients], # process_recipe_ingredients(recipe_data[:ingredients]),
    # instructions: recipe_data[:instructions], # process_recipe_instructions(recipe_data[:instructions]),
    # source: url_source,
    # author: recipe_data[:author].to_s.squish,
    # serves: recipe_data[:serves].to_s.squish,
    # notes: recipe_data[:notes].to_s.squish,
  end

  # Fully process recipe ingredients
  def process_recipe_ingredients(ingredients)
    return if ingredients.blank?
    ingredients = clean_ingredients(ingredients)
    write_ingredients_to_list(ingredients)
  end

  # Remove inconsistencies in ingredient formatting
  def clean_ingredients(ingredients)
    ingredients = ingredients.split(/\s\s+/) if ingredients.is_a? String
    ingredients.delete_if { |item| item.to_s.squish!.gsub(/\s\s+/, ' ').length < 3 }
    # Each of the steps is now in an array.
    ingredients.each do |item|
      # Remove custom lists or line breaks
      item.gsub!(/^\-|\*\s?/, '').to_s.gsub!(/\s\s+/, ' ').to_s.squish!.capitalize
    end
    ingredients
  end

  # Write a list of ingredients
  def write_ingredients_to_list(ingredients)
    ingredients_list = ''
    ingredients.each { |item| ingredients_list += "#{item}\n" }
    ingredients_list.strip
  end

  # Fully process recipe instructions
  def process_recipe_instructions(instructions)
    return '' if instructions.blank?
    steps = form_markdown_for_instructions(clean_instructions(instructions))
    steps.chomp
  end

  # Remove inconsistencies in instruction formatting
  def clean_instructions(steps)
    steps = steps.split(/[\n+]/) if steps.is_a?(String)
    # Each of the steps is now in an array.
    # Remove useless steps
    steps.delete_if do |step|
      step.to_s.squish.length < 3 || step.to_s.match('Preparation')
    end
    steps.map do |step|
      if step.is_a? Hash
        step['itemListElement'][0]['text'].to_s if step['itemListElement']
        # nil.length
      else
        # Remove custom numbering or line breaks
        step.to_s.gsub!(/^\w?\d\.?/, '').to_s.squish!
      end
    end
  end

  # Generate Markdown based on instructions
  def form_markdown_for_instructions(instructions)
    instructions_md = ''
    instructions.each_with_index do |step, id|
      instructions_md += "#{(id + 1)}. #{step.squish}\n"
    end
    instructions_md.strip
  end

  protected

  def inst
    '[itemprop=recipeInstructions]'
  end

  def find_domain(url)
    URI(url).host.to_s.match(/[^\.]+\.\w+$/).to_s
  end

  def find_domain_name(url)
    find_domain(url).match(/(.+)\.\w+/)[1].to_s
  end

  def find_path(url)
    URI(url).path.to_s
  end
end
