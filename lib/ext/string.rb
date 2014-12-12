# encoding: UTF-8
class String
  def replace_special_characters
    #" => 
    #/ =>
    #: =>
    #á => a
    #â => a
    #Æ => ae
    #é => e
    #í => i
    #ú => u
    #û => u
    return self.gsub(/\"/,'').gsub(/\//,'').gsub(/\:/,'').gsub(/á/,'a').gsub(/â/,'a').gsub(/Æ/,'ae').gsub(/é/,'e').gsub(/í/,'i').gsub(/ú/,'u').gsub(/û/,'u')
  end

end

