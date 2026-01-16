# typed: false
# frozen_string_literal: true
# shareable_constant_value: literal

module EmailEmojiHelper
  # Common emojis used in emails with their SVG equivalents
  EMOJI_SVG_MAP = {
    "🔍" => '<svg width="16" height="16" viewBox="0 0 16 16" fill="none" style="display: inline-block; vertical-align: middle;"><path d="M11.742 10.344a6.5 6.5 0 1 0-1.397 1.398h-.001c.03.04.062.078.098.115l3.85 3.85a1 1 0 0 0 1.415-1.414l-3.85-3.85a1.007 1.007 0 0 0-.115-.1zM12 6.5a5.5 5.5 0 1 1-11 0 5.5 5.5 0 0 1 11 0z" fill="currentColor"/></svg>',
    "📧" => '<svg width="16" height="16" viewBox="0 0 16 16" fill="none" style="display: inline-block; vertical-align: middle;"><path d="M2 2a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V4a2 2 0 0 0-2-2H2zM1 4a1 1 0 0 1 1-1h12a1 1 0 0 1 1 1v.217l-7 4.2-7-4.2V4zm13 2.383-4.708 2.825L15 11.105V6.383zm-.034 6.876-5.64-3.471L8 9.583l-.326-.795-5.64 3.47A1 1 0 0 0 2 13h12a1 1 0 0 0 .966-.741zM1 6.383v4.722l5.708-1.897L1 6.383z" fill="currentColor"/></svg>',
    "🌐" => '<svg width="16" height="16" viewBox="0 0 16 16" fill="none" style="display: inline-block; vertical-align: middle;"><path fill-rule="evenodd" d="M8 0C3.58 0 0 3.58 0 8s3.58 8 8 8c4.42 0 8-3.58 8-8s-3.58-8-8-8zM5.53 3a6.95 6.95 0 0 0-.88 3h2.67c.15-1.15.34-2.1.58-3h-2.37zm.5 9c-.24-.9-.43-1.85-.58-3H2.78c.2 1.22.93 2.31 1.93 3.07.22-.02.44-.04.67-.07h.65zm-.78-4c.2-2.77.64-5 1.15-5.6C3.78 2.8 2.81 4.31 2.22 6h3.03zm4.2.07c.2-2.77-.04-5.07-.85-5.07-.81 0-1.05 2.3-.85 5.07h1.7zm-.85 1.93c-.2 2.77.04 5.07.85 5.07.81 0 1.05-2.3.85-5.07h-1.7zm2.73-1.93c-.15 1.15-.34 2.1-.58 3h2.37a6.95 6.95 0 0 0 .88-3h-2.67zm.5-1c.24.9.43 1.85.58 3h2.67a6.95 6.95 0 0 0-.88-3h-2.37zM8 0a8 8 0 1 1 0 16A8 8 0 0 1 8 0z" fill="currentColor"/></svg>',
    "👤" => '<svg width="16" height="16" viewBox="0 0 16 16" fill="none" style="display: inline-block; vertical-align: middle;"><path d="M8 8a3 3 0 1 0 0-6 3 3 0 0 0 0 6zm2-3a2 2 0 1 1-4 0 2 2 0 0 1 4 0zm4 8c0 1-1 1-1 1H3s-1 0-1-1 1-4 6-4 6 3 6 4zm-1-.004c-.001-.246-.154-.986-.832-1.664C11.516 10.68 10.289 10 8 10c-2.29 0-3.516.68-4.168 1.332-.678.678-.83 1.418-.832 1.664h10z" fill="currentColor"/></svg>',
    "💡" => '<svg width="16" height="16" viewBox="0 0 16 16" fill="none" style="display: inline-block; vertical-align: middle;"><path d="M9.5 10.5a.5.5 0 0 1-.5.5h-2a.5.5 0 0 1-.5-.5V10h3v.5zM8 2.5A3.5 3.5 0 0 0 4.5 6c0 1.61.83 2.47 1.46 3.13.35.37.54.65.54 1.37h3c0-.72.19-1 .54-1.37.63-.66 1.46-1.52 1.46-3.13A3.5 3.5 0 0 0 8 2.5zM7 12h2v1H7v-1zm0 2h2v1H7v-1z" fill="currentColor"/></svg>',
    "📦" => '<svg width="16" height="16" viewBox="0 0 16 16" fill="none" style="display: inline-block; vertical-align: middle;"><path d="M8.186 1.113a.5.5 0 0 0-.372 0L1.846 3.5 8 5.961 14.154 3.5 8.186 1.113zM15 4.239l-6.5 2.6v7.922l6.5-2.6V4.24zM7.5 14.762V6.838L1 4.239v7.923l6.5 2.6zM7.443.184a1.5 1.5 0 0 1 1.114 0l7.129 2.852A.5.5 0 0 1 16 3.5v8.662a1 1 0 0 1-.629.928l-7.185 2.874a.5.5 0 0 1-.372 0L.629 13.09a1 1 0 0 1-.629-.928V3.5a.5.5 0 0 1 .314-.464L7.443.184z" fill="currentColor"/></svg>',
    "😔" => '<svg width="16" height="16" viewBox="0 0 16 16" fill="none" style="display: inline-block; vertical-align: middle;"><path d="M8 15A7 7 0 1 1 8 1a7 7 0 0 1 0 14zm0 1A8 8 0 1 0 8 0a8 8 0 0 0 0 16z" fill="currentColor"/><path d="M4.285 12.433a.5.5 0 0 0 .683-.183A3.498 3.498 0 0 1 8 10.5c1.295 0 2.426.703 3.032 1.75a.5.5 0 0 0 .866-.5A4.498 4.498 0 0 0 8 9.5a4.5 4.5 0 0 0-3.898 2.25.5.5 0 0 0 .183.683zM7 6.5C7 7.328 6.552 8 6 8s-1-.672-1-1.5S5.448 5 6 5s1 .672 1 1.5zm4 0c0 .828-.448 1.5-1 1.5s-1-.672-1-1.5S9.448 5 10 5s1 .672 1 1.5z" fill="currentColor"/></svg>',
    "✈️" => '<svg width="16" height="16" viewBox="0 0 16 16" fill="none" style="display: inline-block; vertical-align: middle;"><path d="M6.428 1.151C6.708.591 7.213 0 8 0s1.292.592 1.572 1.151C9.861 1.73 10 2.431 10 3v3.691l5.17 2.585a1.5 1.5 0 0 1 .83 1.342V12a.5.5 0 0 1-.582.493l-5.507-.918-.375 2.253 1.318 1.318A.5.5 0 0 1 10.5 16h-5a.5.5 0 0 1-.354-.854l1.319-1.318-.376-2.253-5.507.918A.5.5 0 0 1 0 12v-1.382a1.5 1.5 0 0 1 .83-1.342L6 6.691V3c0-.568.14-1.271.428-1.849z" fill="currentColor"/></svg>',
    "📱" => '<svg width="16" height="16" viewBox="0 0 16 16" fill="none" style="display: inline-block; vertical-align: middle;"><path d="M11 1a1 1 0 0 1 1 1v12a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V2a1 1 0 0 1 1-1h6zM5 0a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2V2a2 2 0 0 0-2-2H5z" fill="currentColor"/><path d="M8 14a1 1 0 1 0 0-2 1 1 0 0 0 0 2z" fill="currentColor"/></svg>',
    "💾" => '<svg width="16" height="16" viewBox="0 0 16 16" fill="none" style="display: inline-block; vertical-align: middle;"><path d="M8 1a1 1 0 0 1 1 1v6h1.5a.5.5 0 0 1 .354.854l-3 3a.5.5 0 0 1-.708 0l-3-3A.5.5 0 0 1 4.5 8H6V2a1 1 0 0 1 1-1h1z" fill="currentColor"/><path d="M3 15a2 2 0 0 1-2-2v-1a1 1 0 0 1 2 0v1h10v-1a1 1 0 0 1 2 0v1a2 2 0 0 1-2 2H3z" fill="currentColor"/></svg>',
    "🔄" => '<svg width="16" height="16" viewBox="0 0 16 16" fill="none" style="display: inline-block; vertical-align: middle;"><path fill-rule="evenodd" d="M8 3a5 5 0 1 0 4.546 2.914.5.5 0 0 1 .908-.417A6 6 0 1 1 8 2v1z" fill="currentColor"/><path d="M8 4.466V.534a.25.25 0 0 1 .41-.192l2.36 1.966c.12.1.12.284 0 .384L8.41 4.658A.25.25 0 0 1 8 4.466z" fill="currentColor"/></svg>',
    "🌍" => '<svg width="16" height="16" viewBox="0 0 16 16" fill="none" style="display: inline-block; vertical-align: middle;"><path fill-rule="evenodd" d="M8 0a8 8 0 1 0 0 16A8 8 0 0 0 8 0zM2.04 4.326c.325 1.329 2.532 2.54 3.717 3.19.48.263.793.434.743.484-.08.08-.162.158-.242.234-.416.396-.787.749-.758 1.266.035.634.618.824 1.214 1.017.577.188 1.168.38 1.286.983.082.417-.075.988-.22 1.52-.215.782-.406 1.48.22 1.48 1.5-.5 3.798-3.186 4-5 .138-1.243-2-2-3.5-2.5-.478-.16-.755.081-.99.284-.172.15-.322.279-.51.216-.445-.148-2.5-2-1.5-2.5.78-.39.952-.171 1.227.182.078.1.155.299.261.602.097.267.132.717.132.717.671-.175 1.232-.205 1.817-.208.585-.003 1.375.017 2.05-.17.94-.262 1.007-.801.677-1.410-.47-.87-1.588-1.753-2.63-2.708C8.04 1.920 7.022 1.458 6.087 1.39 5.24 1.329 4.48 1.504 3.799 2.007a6.723 6.723 0 0 0-1.759 2.319z" fill="currentColor"/></svg>',
    "📄" => '<svg width="16" height="16" viewBox="0 0 16 16" fill="none" style="display: inline-block; vertical-align: middle;"><path d="M4 0a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h8a2 2 0 0 0 2-2V2a2 2 0 0 0-2-2H4zm0 1h8a1 1 0 0 1 1 1v12a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V2a1 1 0 0 1 1-1z" fill="currentColor"/></svg>'
  }.freeze

  def replace_emojis_with_svg(text)
    return text if text.blank?

    result = text.dup
    EMOJI_SVG_MAP.each do |emoji, svg|
      result = result.gsub(emoji, svg)
    end
    result
  end

  def svg_email_safe(text)
    replace_emojis_with_svg(text)
  end
end
