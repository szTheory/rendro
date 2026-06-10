defmodule Rendro.Text.ScriptTags do
  @moduledoc false

  @doc """
  Maps Unicode script atom names (as returned by `Unicode.script/1`) to
  OpenType 4-letter script tags (atoms).

  If the input atom is not in the mapping table, it is returned unchanged
  (passthrough fallback — prevents crashes on scripts not yet in the table).

  Source data: derived from OpenType script tag registry and
  `UnicodeData.Script.script_to_tag/1` mapping table (unicode_data 0.8.0),
  adapted from string-input/string-output to atom-input/atom-output form.
  Covers Unicode 12.0 script inventory plus all 20 complex-shaping scripts
  gated in `Rendro.Text.Shaper.Simple`.
  """
  @spec to_opentype_tag(atom()) :: atom()

  # Joining scripts (Arabic family)
  def to_opentype_tag(:arabic), do: :arab
  def to_opentype_tag(:imperial_aramaic), do: :armi
  def to_opentype_tag(:avestan), do: :avst
  def to_opentype_tag(:syriac), do: :syrc
  def to_opentype_tag(:thaana), do: :thaa
  def to_opentype_tag(:nko), do: :nkoo
  def to_opentype_tag(:mongolian), do: :mong
  def to_opentype_tag(:mandaic), do: :mand
  def to_opentype_tag(:manichaean), do: :mani
  def to_opentype_tag(:mende_kikakui), do: :mend
  def to_opentype_tag(:meroitic_cursive), do: :merc
  def to_opentype_tag(:meroitic_hieroglyphs), do: :mero
  def to_opentype_tag(:nabataean), do: :nbat
  def to_opentype_tag(:old_north_arabian), do: :narb
  def to_opentype_tag(:old_south_arabian), do: :sarb
  def to_opentype_tag(:old_turkic), do: :orkh
  def to_opentype_tag(:palmyrene), do: :palm
  def to_opentype_tag(:psalter_pahlavi), do: :phlp
  def to_opentype_tag(:inscriptional_pahlavi), do: :phli
  def to_opentype_tag(:inscriptional_parthian), do: :prti
  def to_opentype_tag(:samaritan), do: :samr
  def to_opentype_tag(:sogdian), do: :sogd
  def to_opentype_tag(:old_sogdian), do: :sogo
  def to_opentype_tag(:hanifi_rohingya), do: :rohg

  # Hebrew / RTL
  def to_opentype_tag(:hebrew), do: :hebr
  def to_opentype_tag(:phoenician), do: :phnx
  def to_opentype_tag(:lydian), do: :lydi

  # Indic scripts
  def to_opentype_tag(:devanagari), do: :deva
  def to_opentype_tag(:bengali), do: :beng
  def to_opentype_tag(:gurmukhi), do: :guru
  def to_opentype_tag(:gujarati), do: :gujr
  def to_opentype_tag(:oriya), do: :orya
  def to_opentype_tag(:tamil), do: :taml
  def to_opentype_tag(:telugu), do: :telu
  def to_opentype_tag(:kannada), do: :knda
  def to_opentype_tag(:malayalam), do: :mlym
  def to_opentype_tag(:sinhala), do: :sinh
  def to_opentype_tag(:brahmi), do: :brah
  def to_opentype_tag(:chakma), do: :cakm
  def to_opentype_tag(:grantha), do: :gran
  def to_opentype_tag(:kaithi), do: :kthi
  def to_opentype_tag(:khojki), do: :khoj
  def to_opentype_tag(:khudawadi), do: :sind
  def to_opentype_tag(:limbu), do: :limb
  def to_opentype_tag(:mahajani), do: :mahj
  def to_opentype_tag(:modi), do: :modi
  def to_opentype_tag(:newa), do: :newa
  def to_opentype_tag(:sharada), do: :shrd
  def to_opentype_tag(:siddham), do: :sidd
  def to_opentype_tag(:sora_sompeng), do: :sora
  def to_opentype_tag(:syloti_nagri), do: :sylo
  def to_opentype_tag(:takri), do: :takr
  def to_opentype_tag(:tirhuta), do: :tirh
  def to_opentype_tag(:dogra), do: :dogr
  def to_opentype_tag(:gunjala_gondi), do: :gong
  def to_opentype_tag(:masaram_gondi), do: :gonm

  # SEA (South/Southeast Asian)
  def to_opentype_tag(:thai), do: :thai
  def to_opentype_tag(:lao), do: :laoo
  def to_opentype_tag(:khmer), do: :khmr
  def to_opentype_tag(:myanmar), do: :mymr
  def to_opentype_tag(:javanese), do: :java
  def to_opentype_tag(:kayah_li), do: :kali
  def to_opentype_tag(:tai_le), do: :tale
  def to_opentype_tag(:new_tai_lue), do: :talu
  def to_opentype_tag(:tai_tham), do: :lana
  def to_opentype_tag(:tai_viet), do: :tavt
  def to_opentype_tag(:meetei_mayek), do: :mtei
  def to_opentype_tag(:balinese), do: :bali
  def to_opentype_tag(:batak), do: :batk
  def to_opentype_tag(:buginese), do: :bugi
  def to_opentype_tag(:buhid), do: :buhd
  def to_opentype_tag(:hanunoo), do: :hano
  def to_opentype_tag(:rejang), do: :rjng
  def to_opentype_tag(:sundanese), do: :sund
  def to_opentype_tag(:tagalog), do: :tglg
  def to_opentype_tag(:tagbanwa), do: :tagb
  def to_opentype_tag(:pahawh_hmong), do: :hmng
  def to_opentype_tag(:pau_cin_hau), do: :pauc
  def to_opentype_tag(:makasar), do: :maka

  # Tibetan / Central Asian
  def to_opentype_tag(:tibetan), do: :tibt
  def to_opentype_tag(:marchen), do: :marc
  def to_opentype_tag(:soyombo), do: :soyo
  def to_opentype_tag(:zanabazar_square), do: :zanb
  def to_opentype_tag(:phags_pa), do: :phag

  # European scripts
  def to_opentype_tag(:latin), do: :latn
  def to_opentype_tag(:greek), do: :grek
  def to_opentype_tag(:cyrillic), do: :cyrl
  def to_opentype_tag(:armenian), do: :armn
  def to_opentype_tag(:georgian), do: :geor
  def to_opentype_tag(:glagolitic), do: :glag
  def to_opentype_tag(:gothic), do: :goth
  def to_opentype_tag(:runic), do: :runr
  def to_opentype_tag(:ogham), do: :ogam
  def to_opentype_tag(:shavian), do: :shaw
  def to_opentype_tag(:elbasan), do: :elba
  def to_opentype_tag(:caucasian_albanian), do: :aghb
  def to_opentype_tag(:old_italic), do: :ital
  def to_opentype_tag(:old_permic), do: :perm
  def to_opentype_tag(:osage), do: :osge

  # CJK and East Asian scripts
  def to_opentype_tag(:han), do: :hani
  def to_opentype_tag(:hiragana), do: :hira
  def to_opentype_tag(:katakana), do: :kana
  def to_opentype_tag(:hangul), do: :hang
  def to_opentype_tag(:bopomofo), do: :bopo
  def to_opentype_tag(:yi), do: :yiii
  def to_opentype_tag(:lisu), do: :lisu
  def to_opentype_tag(:miao), do: :plrd
  def to_opentype_tag(:nushu), do: :nshu
  def to_opentype_tag(:tangut), do: :tang

  # African scripts
  def to_opentype_tag(:ethiopic), do: :ethi
  def to_opentype_tag(:bamum), do: :bamu
  def to_opentype_tag(:bassa_vah), do: :bass
  def to_opentype_tag(:duployan), do: :dupl
  def to_opentype_tag(:adlam), do: :adlm
  def to_opentype_tag(:medefaidrin), do: :medf
  def to_opentype_tag(:mro), do: :mroo
  def to_opentype_tag(:warang_citi), do: :wara
  def to_opentype_tag(:wancho), do: :wcho

  # American scripts
  def to_opentype_tag(:cherokee), do: :cher
  def to_opentype_tag(:canadian_aboriginal), do: :cans
  def to_opentype_tag(:ol_chiki), do: :olck
  def to_opentype_tag(:deseret), do: :dsrt
  def to_opentype_tag(:osmanya), do: :osma

  # Historic and special scripts
  def to_opentype_tag(:ahom), do: :ahom
  def to_opentype_tag(:anatolian_hieroglyphs), do: :hluw
  def to_opentype_tag(:braille), do: :brai
  def to_opentype_tag(:carian), do: :cari
  def to_opentype_tag(:cham), do: :cham
  def to_opentype_tag(:coptic), do: :copt
  def to_opentype_tag(:cuneiform), do: :xsux
  def to_opentype_tag(:cypriot), do: :cprt
  def to_opentype_tag(:egyptian_hieroglyphs), do: :egyp
  def to_opentype_tag(:elymaic), do: :elym
  def to_opentype_tag(:hatran), do: :hatr
  def to_opentype_tag(:kharoshthi), do: :khar
  def to_opentype_tag(:lepcha), do: :lepc
  def to_opentype_tag(:linear_a), do: :lina
  def to_opentype_tag(:linear_b), do: :linb
  def to_opentype_tag(:lycian), do: :lyci
  def to_opentype_tag(:multani), do: :mult
  def to_opentype_tag(:nandinagari), do: :nand
  def to_opentype_tag(:nyiakeng_puachue_hmong), do: :hmnp
  def to_opentype_tag(:old_hungarian), do: :hung
  def to_opentype_tag(:old_persian), do: :xpeo
  def to_opentype_tag(:old_uyghur), do: :ougr
  def to_opentype_tag(:saurashtra), do: :saur
  def to_opentype_tag(:signwriting), do: :sgnw
  def to_opentype_tag(:tifinagh), do: :tfng
  def to_opentype_tag(:ugaritic), do: :ugar
  def to_opentype_tag(:bhaiksuki), do: :bhks

  # Fallback: pass atom through unchanged
  # Prevents crashes on scripts not in the table
  def to_opentype_tag(script), do: script
end
