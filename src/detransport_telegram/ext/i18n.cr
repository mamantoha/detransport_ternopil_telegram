module I18n
  class Config
    protected def translations_data : TranslationsHash
      @translations_data ||= begin
        tr_hash = TranslationsHash.new
        loaders.each do |loader|
          effective_translations = loader.load.select do |locale, _|
            available_locales.nil? || available_locales.not_nil!.empty? || available_locales.not_nil!.includes?(locale)
          end
          tr_hash = tr_hash.deep_merge(effective_translations)
        end
        tr_hash
      end
    end
  end
end
