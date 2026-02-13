# frozen_string_literal: true
# shareable_constant_value: literal

def safe_require(lib)
  require lib
rescue Exception => e
  Rails.logger.debug "Failed to require #{lib}: #{e.message}"
  $LOADED_FEATURES << "#{lib}.rb" unless lib.end_with?(".rb")
end

# Applique
# safe_require 'facets/applique/file_helpers'

# Array Extensions (52 total)
safe_require "facets/array/after"
safe_require "facets/array/arrange"
safe_require "facets/array/before"
safe_require "facets/array/collapse"
safe_require "facets/array/collisions"
safe_require "facets/array/commonality"
safe_require "facets/array/conjoin"
safe_require "facets/array/contains"
safe_require "facets/array/delete"
safe_require "facets/array/delete_unless"
safe_require "facets/array/delete_values"
safe_require "facets/array/divide"
safe_require "facets/array/duplicates"
safe_require "facets/array/each_overlap"
safe_require "facets/array/each_pair"
safe_require "facets/array/each_value"
safe_require "facets/array/entropy"
safe_require "facets/array/extract_options"
safe_require "facets/array/from"
safe_require "facets/array/indexable"
safe_require "facets/array/intersection"
safe_require "facets/array/median"
safe_require "facets/array/merge"
safe_require "facets/array/missing"
safe_require "facets/array/mode"
safe_require "facets/array/nonuniq"
safe_require "facets/array/not_empty"
safe_require "facets/array/occur"
safe_require "facets/array/occurrence"
safe_require "facets/array/only"
safe_require "facets/array/op_pow"
safe_require "facets/array/pad"
safe_require "facets/array/peek"
safe_require "facets/array/poke"
safe_require "facets/array/probability"
safe_require "facets/array/pull"
safe_require "facets/array/recurse"
safe_require "facets/array/recursively"
safe_require "facets/array/reject_values"
safe_require "facets/array/splice"
safe_require "facets/array/split"
safe_require "facets/array/squeeze"
safe_require "facets/array/step"
safe_require "facets/array/store"
safe_require "facets/array/thru"
safe_require "facets/array/to_h"
safe_require "facets/array/traverse"
safe_require "facets/array/uniq_by"
safe_require "facets/array/unique_permutation"
safe_require "facets/array/zip"

# Binding Extensions (12 total)
safe_require "facets/binding/__callee__"
safe_require "facets/binding/__method__"
safe_require "facets/binding/call_stack"
safe_require "facets/binding/caller"
safe_require "facets/binding/callstack"
safe_require "facets/binding/defined"
# safe_require 'facets/binding/local_variables'
safe_require "facets/binding/op"
safe_require "facets/binding/op_get"
safe_require "facets/binding/op_set"
safe_require "facets/binding/self"
safe_require "facets/binding/with"

# Boolean
safe_require "facets/boolean"

# Cattr
# safe_require 'facets/cattr'

# Class Extensions (11 total)
safe_require "facets/class/descendants"
safe_require "facets/class/hierarchically"
safe_require "facets/class/methodize"
safe_require "facets/class/pathize"
safe_require "facets/class/preallocate"
safe_require "facets/class/singleton"
safe_require "facets/class/singleton_class"
safe_require "facets/class/subclasses"
safe_require "facets/class/to_proc"

# Comparable Extensions (7 total)
safe_require "facets/comparable/at_least"
safe_require "facets/comparable/at_most"
safe_require "facets/comparable/bound"
safe_require "facets/comparable/cap"
safe_require "facets/comparable/clip"
safe_require "facets/comparable/cmp"
safe_require "facets/comparable/op_get"

# Denumerable
safe_require "facets/denumerable"

# Dir Extensions (7 total)
safe_require "facets/dir/ascend"
safe_require "facets/dir/descend"
safe_require "facets/dir/each_child"
safe_require "facets/dir/lookup"
safe_require "facets/dir/multiglob"
safe_require "facets/dir/parent"
safe_require "facets/dir/recurse"

# Enumerable Extensions (41 total)
safe_require "facets/enumerable/accumulate"
# safe_require 'facets/enumerable/apply'
safe_require "facets/enumerable/associate"
safe_require "facets/enumerable/cluster"
safe_require "facets/enumerable/collect_with_index"
safe_require "facets/enumerable/compact_map"
safe_require "facets/enumerable/defer"
safe_require "facets/enumerable/each_by"
safe_require "facets/enumerable/every"
safe_require "facets/enumerable/ewise"
safe_require "facets/enumerable/exclude"
safe_require "facets/enumerable/expand"
safe_require "facets/enumerable/filter"
safe_require "facets/enumerable/find_yield"
safe_require "facets/enumerable/frequency"
safe_require "facets/enumerable/graph"
safe_require "facets/enumerable/hashify"
safe_require "facets/enumerable/hinge"
safe_require "facets/enumerable/incase"
safe_require "facets/enumerable/key_by"
safe_require "facets/enumerable/map_by"
safe_require "facets/enumerable/map_detect"
safe_require "facets/enumerable/map_send"
safe_require "facets/enumerable/map_to"
safe_require "facets/enumerable/map_with"
safe_require "facets/enumerable/map_with_index"
safe_require "facets/enumerable/mash"
safe_require "facets/enumerable/modulate"
safe_require "facets/enumerable/occur"
safe_require "facets/enumerable/only"
safe_require "facets/enumerable/organize_by"
safe_require "facets/enumerable/pair"
safe_require "facets/enumerable/per"
safe_require "facets/enumerable/purge"
safe_require "facets/enumerable/recursively"
safe_require "facets/enumerable/squeeze"
safe_require "facets/enumerable/sum"
safe_require "facets/enumerable/unassociate"
safe_require "facets/enumerable/uniq_by"
safe_require "facets/enumerable/value_by"
safe_require "facets/enumerable/visit"
safe_require "facets/enumerable/zip_map"

# Enumerator Extensions
safe_require "facets/enumerator/fx"
safe_require "facets/enumerator/lazy/squeeze"

# Essentials
# safe_require 'facets/essentials'

# Exception Extensions (5 total)
safe_require "facets/exception/detail"
safe_require "facets/exception/error_print"
safe_require "facets/exception/raised"
safe_require "facets/exception/set_message"
safe_require "facets/exception/suppress"

# File Extensions (17 total)
safe_require "facets/file/append"
safe_require "facets/file/atomic_id"
safe_require "facets/file/atomic_open"
safe_require "facets/file/atomic_write"
safe_require "facets/file/common_path"
safe_require "facets/file/create"
safe_require "facets/file/ext"
safe_require "facets/file/null"
safe_require "facets/file/read_binary"
safe_require "facets/file/read_list"
safe_require "facets/file/rewrite"
safe_require "facets/file/rootname"
safe_require "facets/file/sanitize"
safe_require "facets/file/split_all"
safe_require "facets/file/split_root"
safe_require "facets/file/write"
safe_require "facets/file/writelines"

# FileTest Extensions (6 total)
safe_require "facets/filetest/absolute"
safe_require "facets/filetest/contains"
safe_require "facets/filetest/relative"
safe_require "facets/filetest/root"
safe_require "facets/filetest/safe"
safe_require "facets/filetest/separator_pattern"

# Fixnum
safe_require "facets/fixnum"

# Float Extensions
safe_require "facets/float/round_to"

# Functor
safe_require "facets/functor"

# Hash Extensions (55 total)
safe_require "facets/hash/alias"
safe_require "facets/hash/argumentize"
safe_require "facets/hash/at"
safe_require "facets/hash/autonew"
safe_require "facets/hash/collate"
safe_require "facets/hash/count"
safe_require "facets/hash/data"
safe_require "facets/hash/dearray_values"
safe_require "facets/hash/deep_merge"
safe_require "facets/hash/deep_rekey"
safe_require "facets/hash/delete"
safe_require "facets/hash/delete_at"
safe_require "facets/hash/delete_unless"
safe_require "facets/hash/delete_values"
safe_require "facets/hash/diff"
safe_require "facets/hash/each_with_key"
safe_require "facets/hash/except"
safe_require "facets/hash/fetch_nested"
safe_require "facets/hash/graph"
safe_require "facets/hash/insert"
safe_require "facets/hash/inverse"
safe_require "facets/hash/join"
safe_require "facets/hash/keys"
safe_require "facets/hash/mash"
safe_require "facets/hash/new_with"
safe_require "facets/hash/only_keys"
safe_require "facets/hash/op"
safe_require "facets/hash/op_add"
safe_require "facets/hash/op_and"
safe_require "facets/hash/op_mul"
safe_require "facets/hash/op_or"
safe_require "facets/hash/op_push"
safe_require "facets/hash/op_sub"
safe_require "facets/hash/recurse"
safe_require "facets/hash/recursively"
safe_require "facets/hash/rekey"
safe_require "facets/hash/replace_each"
safe_require "facets/hash/revalue"
safe_require "facets/hash/reverse_merge"
safe_require "facets/hash/slice"
safe_require "facets/hash/stringify_keys"
safe_require "facets/hash/subset"
safe_require "facets/hash/swap"
safe_require "facets/hash/symbolize_keys"
safe_require "facets/hash/to_mod"
safe_require "facets/hash/to_options"
safe_require "facets/hash/to_proc"
safe_require "facets/hash/to_struct"
safe_require "facets/hash/traverse"
safe_require "facets/hash/update"
safe_require "facets/hash/update_each"
safe_require "facets/hash/update_keys"
safe_require "facets/hash/update_values"
safe_require "facets/hash/weave"
safe_require "facets/hash/zip"

# Indexable
safe_require "facets/indexable"

# Integer Extensions (7 total)
safe_require "facets/integer/bit"
safe_require "facets/integer/bitmask"
safe_require "facets/integer/factorial"
safe_require "facets/integer/multiple"
safe_require "facets/integer/of"
safe_require "facets/integer/ordinal"
safe_require "facets/integer/roman"

# Kernel Extensions (71 total)
safe_require "facets/kernel/__class__"
safe_require "facets/kernel/__dir__"
safe_require "facets/kernel/__get__"
safe_require "facets/kernel/__set__"
safe_require "facets/kernel/as"
safe_require "facets/kernel/ask"
safe_require "facets/kernel/assign"
safe_require "facets/kernel/assign_from"
safe_require "facets/kernel/attr_singleton"
safe_require "facets/kernel/blank"
safe_require "facets/kernel/call_stack"
safe_require "facets/kernel/callstack"
safe_require "facets/kernel/case"
safe_require "facets/kernel/complete"
safe_require "facets/kernel/constant"
safe_require "facets/kernel/d"
safe_require "facets/kernel/deep_clone"
safe_require "facets/kernel/deep_copy"
safe_require "facets/kernel/demo"
safe_require "facets/kernel/disable_warnings"
safe_require "facets/kernel/eigen"
safe_require "facets/kernel/eigenclass"
safe_require "facets/kernel/enable_warnings"
safe_require "facets/kernel/ergo"
safe_require "facets/kernel/extend"
safe_require "facets/kernel/extension"
safe_require "facets/kernel/false"
safe_require "facets/kernel/here"
safe_require "facets/kernel/hierarchical_send"
safe_require "facets/kernel/identical"
safe_require "facets/kernel/in"
safe_require "facets/kernel/instance_assign"
safe_require "facets/kernel/instance_class"
safe_require "facets/kernel/instance_exec"
safe_require "facets/kernel/instance_extract"
safe_require "facets/kernel/instance_replace"
safe_require "facets/kernel/instance_send"
safe_require "facets/kernel/like"
safe_require "facets/kernel/load_all"
safe_require "facets/kernel/load_relative"
safe_require "facets/kernel/maybe"
# safe_require 'facets/kernel/memo'
safe_require "facets/kernel/meta"
safe_require "facets/kernel/meta_alias"
safe_require "facets/kernel/meta_class"
safe_require "facets/kernel/meta_def"
safe_require "facets/kernel/meta_eval"
safe_require "facets/kernel/method"
safe_require "facets/kernel/no"
safe_require "facets/kernel/not"
safe_require "facets/kernel/not_nil"
# safe_require 'facets/kernel/object_class'
safe_require "facets/kernel/object_hexid"
safe_require "facets/kernel/object_send"
safe_require "facets/kernel/p"
safe_require "facets/kernel/presence"
safe_require "facets/kernel/present"
safe_require "facets/kernel/qua_class"
safe_require "facets/kernel/require_all"
safe_require "facets/kernel/respond"
safe_require "facets/kernel/returning"
safe_require "facets/kernel/silence"
safe_require "facets/kernel/silence_warnings"
safe_require "facets/kernel/singleton_class"
safe_require "facets/kernel/super_method"
safe_require "facets/kernel/tap"
safe_require "facets/kernel/temporarily"
safe_require "facets/kernel/trap_chain"
safe_require "facets/kernel/true"
safe_require "facets/kernel/try"
safe_require "facets/kernel/val"
safe_require "facets/kernel/with"
safe_require "facets/kernel/writers"
safe_require "facets/kernel/y"
safe_require "facets/kernel/yes"

# Lazy
safe_require "facets/lazy"

# Load Path Extensions
safe_require "facets/load_path/search"

# MatchData Extensions
safe_require "facets/matchdata/match"
safe_require "facets/matchdata/matchset"

# Metaid
safe_require "facets/metaid"

# Method Extensions (7 total)
safe_require "facets/method/composition"
safe_require "facets/method/curry"
safe_require "facets/method/memoize"
safe_require "facets/method/op_mul"
safe_require "facets/method/op_pow"
safe_require "facets/method/partial"
safe_require "facets/method/public"

# Module Extensions (62 total)
safe_require "facets/module/abstract"
safe_require "facets/module/alias_accessor"
safe_require "facets/module/alias_class_method"
safe_require "facets/module/alias_method_chain"
safe_require "facets/module/alias_module_function"
safe_require "facets/module/all_instance_methods"
safe_require "facets/module/ancestor"
safe_require "facets/module/anonymous"
safe_require "facets/module/attr_class_accessor"
safe_require "facets/module/attr_setter"
safe_require "facets/module/attr_tester"
safe_require "facets/module/attr_validator"
safe_require "facets/module/basename"
safe_require "facets/module/can"
# safe_require 'facets/module/cattr'
safe_require "facets/module/class"
safe_require "facets/module/class_accessor"
safe_require "facets/module/class_def"
safe_require "facets/module/class_extend"
safe_require "facets/module/class_inheritor"
safe_require "facets/module/class_method_defined"
safe_require "facets/module/copy_inheritor"
safe_require "facets/module/enclosure"
safe_require "facets/module/enclosures"
safe_require "facets/module/extend"
safe_require "facets/module/home"
safe_require "facets/module/homename"
safe_require "facets/module/housing"
safe_require "facets/module/include_as"
safe_require "facets/module/include_function_module"
safe_require "facets/module/instance_function"
safe_require "facets/module/instance_method"
safe_require "facets/module/instance_method_defined"
safe_require "facets/module/integrate"
safe_require "facets/module/is"
safe_require "facets/module/lastname"
safe_require "facets/module/let"
# safe_require 'facets/module/mattr'
safe_require "facets/module/memoize"
safe_require "facets/module/method_clash"
safe_require "facets/module/method_space"
safe_require "facets/module/methodize"
safe_require "facets/module/modname"
safe_require "facets/module/module_def"
safe_require "facets/module/module_load"
safe_require "facets/module/nodef"
safe_require "facets/module/op"
safe_require "facets/module/op_add"
safe_require "facets/module/op_mul"
safe_require "facets/module/op_sub"
safe_require "facets/module/pathize"
safe_require "facets/module/preextend"
safe_require "facets/module/redefine_method"
safe_require "facets/module/redirect_method"
safe_require "facets/module/remove"
safe_require "facets/module/rename_method"
safe_require "facets/module/revise"
safe_require "facets/module/set"
safe_require "facets/module/singleton_method_defined"
safe_require "facets/module/spacename"
safe_require "facets/module/to_obj"
safe_require "facets/module/wrap_method"

# NA
safe_require "facets/na"

# NilClass Extensions
safe_require "facets/nilclass/ergo"

# Numeric Extensions (9 total)
safe_require "facets/numeric/approx"
safe_require "facets/numeric/close"
safe_require "facets/numeric/distance"
safe_require "facets/numeric/length"
safe_require "facets/numeric/negative"
safe_require "facets/numeric/positive"
safe_require "facets/numeric/range"
safe_require "facets/numeric/round_to"
safe_require "facets/numeric/spacing"

# Object Extensions (5 total)
safe_require "facets/object/clone"
safe_require "facets/object/dup"
safe_require "facets/object/itself"
safe_require "facets/object/object_state"
safe_require "facets/object/try_dup"

# ObjectSpace Extensions
safe_require "facets/objectspace/classes"
safe_require "facets/objectspace/op_fetch"

# Proc Extensions (7 total)
safe_require "facets/proc/bind"
safe_require "facets/proc/bind_to"
safe_require "facets/proc/compose"
safe_require "facets/proc/partial"
safe_require "facets/proc/to_method"
safe_require "facets/proc/update"
safe_require "facets/proc/wrap"

# Process Extensions
safe_require "facets/process/daemon"

# Range Extensions (8 total)
safe_require "facets/range/combine"
safe_require "facets/range/op_add"
safe_require "facets/range/op_sub"
safe_require "facets/range/overlap"
safe_require "facets/range/quantile"
safe_require "facets/range/to_rng"
safe_require "facets/range/umbrella"
safe_require "facets/range/within"

# Regexp Extensions (6 total)
safe_require "facets/regexp/arity"
safe_require "facets/regexp/multiline"
safe_require "facets/regexp/op_add"
safe_require "facets/regexp/op_or"
safe_require "facets/regexp/to_proc"
safe_require "facets/regexp/to_re"

# Roman
safe_require "facets/roman"

# String Extensions (72 total)
safe_require "facets/string/acronym"
safe_require "facets/string/align"
safe_require "facets/string/ascii_only"
safe_require "facets/string/bracket"
safe_require "facets/string/briefcase"
safe_require "facets/string/camelcase"
safe_require "facets/string/capitalized"
safe_require "facets/string/characters"
safe_require "facets/string/cleanlines"
safe_require "facets/string/cleave"
safe_require "facets/string/cmp"
safe_require "facets/string/compress_lines"
safe_require "facets/string/crypt"
safe_require "facets/string/divide"
safe_require "facets/string/each_match"
safe_require "facets/string/each_word"
safe_require "facets/string/edit_distance"
safe_require "facets/string/ends_with"
safe_require "facets/string/exclude"
safe_require "facets/string/expand_tab"
safe_require "facets/string/file"
safe_require "facets/string/fold"
safe_require "facets/string/indent"
safe_require "facets/string/index_all"
safe_require "facets/string/indexable"
safe_require "facets/string/interpolate"
safe_require "facets/string/lchomp"
safe_require "facets/string/line_wrap"
safe_require "facets/string/linear"
safe_require "facets/string/lowercase"
safe_require "facets/string/margin"
safe_require "facets/string/methodize"
safe_require "facets/string/modulize"
safe_require "facets/string/mscan"
safe_require "facets/string/natcmp"
safe_require "facets/string/nchar"
safe_require "facets/string/newlines"
safe_require "facets/string/number"
safe_require "facets/string/op_div"
safe_require "facets/string/op_sub"
safe_require "facets/string/outdent"
safe_require "facets/string/pathize"
safe_require "facets/string/quote"
safe_require "facets/string/random"
safe_require "facets/string/range"
safe_require "facets/string/range_all"
safe_require "facets/string/range_of_line"
safe_require "facets/string/remove"
safe_require "facets/string/rewrite"
safe_require "facets/string/roman"
safe_require "facets/string/rotate"
safe_require "facets/string/shatter"
safe_require "facets/string/similarity"
safe_require "facets/string/snakecase"
safe_require "facets/string/splice"
safe_require "facets/string/squish"
safe_require "facets/string/starts_with"
safe_require "facets/string/store"
safe_require "facets/string/subtract"
safe_require "facets/string/titlecase"
safe_require "facets/string/to_re"
safe_require "facets/string/to_rx"
safe_require "facets/string/trim"
safe_require "facets/string/unbracket"
safe_require "facets/string/underscore"
safe_require "facets/string/unfold"
safe_require "facets/string/unindent"
safe_require "facets/string/unquote"
safe_require "facets/string/uppercase"
safe_require "facets/string/variablize"
safe_require "facets/string/word_wrap"
safe_require "facets/string/words"
safe_require "facets/string/xor"

# Struct Extensions
safe_require "facets/struct/attributes"
safe_require "facets/struct/replace"

# Symbol Extensions (14 total)
safe_require "facets/symbol/as_s"
safe_require "facets/symbol/bang"
# safe_require 'facets/symbol/call'
safe_require "facets/symbol/chomp"
safe_require "facets/symbol/generate"
safe_require "facets/symbol/not"
safe_require "facets/symbol/op_div"
safe_require "facets/symbol/plain"
safe_require "facets/symbol/query"
safe_require "facets/symbol/reader"
safe_require "facets/symbol/setter"
safe_require "facets/symbol/succ"
safe_require "facets/symbol/thrown"
safe_require "facets/symbol/variablize"
safe_require "facets/symbol/writer"

# Time Extensions (14 total)
safe_require "facets/time/ago"
safe_require "facets/time/change"
safe_require "facets/time/dst_adjustment"
safe_require "facets/time/elapse"
safe_require "facets/time/future"
safe_require "facets/time/hence"
safe_require "facets/time/in"
safe_require "facets/time/less"
safe_require "facets/time/past"
safe_require "facets/time/round_to"
safe_require "facets/time/set"
safe_require "facets/time/shift"
safe_require "facets/time/stamp"
safe_require "facets/time/to_time"
safe_require "facets/time/trunc"

# UnboundMethod Extensions
safe_require "facets/unboundmethod/arguments"

# ============================================================================
# STANDARD LIBRARY EXTENSIONS (lib/standard/facets/)
# ============================================================================

# Against
safe_require "facets/against"

# Argvector
safe_require "facets/argvector"

# BasicObject
safe_require "facets/basicobject"

# Binding Standard Extensions
safe_require "facets/binding/block_exec"

# CGI Extensions
# safe_require "facets/cgi/esc"
# safe_require "facets/cgi/escape_html"
# safe_require "facets/cgi/marshal"

# CLI
safe_require "facets/cli"

# Cloneable
safe_require "facets/cloneable"

# Continuation
safe_require "facets/continuation"

# Date
safe_require "facets/date"

# Digest Extensions
safe_require "facets/digest/base64digest"
# safe_require 'facets/digest/salted_digest'

# Enumargs
safe_require "facets/enumargs"

# Equitable
safe_require "facets/equitable"

# ERB
safe_require "facets/erb"

# FileUtils Extensions
safe_require "facets/fileutils/amass"
safe_require "facets/fileutils/cp_rx"
safe_require "facets/fileutils/head"
safe_require "facets/fileutils/ln_r"
safe_require "facets/fileutils/outofdate"
safe_require "facets/fileutils/safe_ln"
safe_require "facets/fileutils/slice"
safe_require "facets/fileutils/stage"
safe_require "facets/fileutils/tail"
safe_require "facets/fileutils/wc"
safe_require "facets/fileutils/whereis"
safe_require "facets/fileutils/which"

# Find Extensions
safe_require "facets/find/select"

# Gem Extensions
safe_require "facets/gem/search"
safe_require "facets/gem/specification/current_specs"
safe_require "facets/gem/specification/find_requireable_file"

# GetoptLong
# safe_require 'facets/getoptlong'

# HashBuilder
safe_require "facets/hash_builder"

# Instantiable
safe_require "facets/instantiable"

# Interval
safe_require "facets/interval"

# LoadMonitor
# safe_require 'facets/load_monitor'

# Math Extensions (61 total)
safe_require "facets/math/abs"
safe_require "facets/math/acosec"
safe_require "facets/math/acot"
safe_require "facets/math/acoth"
safe_require "facets/math/acsc"
safe_require "facets/math/acsch"
safe_require "facets/math/amd"
safe_require "facets/math/approx_equal"
safe_require "facets/math/asec"
safe_require "facets/math/asech"
safe_require "facets/math/atkinson_index"
safe_require "facets/math/beta"
safe_require "facets/math/cdf"
safe_require "facets/math/ceil"
safe_require "facets/math/cosec"
safe_require "facets/math/cosech"
safe_require "facets/math/cot"
safe_require "facets/math/coth"
safe_require "facets/math/csc"
safe_require "facets/math/csch"
safe_require "facets/math/delta"
safe_require "facets/math/distance"
safe_require "facets/math/ec"
safe_require "facets/math/epsilon"
safe_require "facets/math/exp10"
safe_require "facets/math/exp2"
safe_require "facets/math/factorial"
safe_require "facets/math/floor"
safe_require "facets/math/gcd"
safe_require "facets/math/gini_coefficient"
safe_require "facets/math/kldivergence"
safe_require "facets/math/lcm"
safe_require "facets/math/lgamma"
safe_require "facets/math/linsolve"
safe_require "facets/math/lngamma"
safe_require "facets/math/log2"
safe_require "facets/math/max"
safe_require "facets/math/mean"
safe_require "facets/math/median"
safe_require "facets/math/min"
safe_require "facets/math/percentile"
safe_require "facets/math/pow"
safe_require "facets/math/pstd"
safe_require "facets/math/pvariance"
safe_require "facets/math/rmd"
safe_require "facets/math/root"
safe_require "facets/math/round"
safe_require "facets/math/sec"
safe_require "facets/math/sech"
safe_require "facets/math/sign"
safe_require "facets/math/sinc"
safe_require "facets/math/sqr"
safe_require "facets/math/sqsolve"
safe_require "facets/math/std"
safe_require "facets/math/stderr"
safe_require "facets/math/sum"
safe_require "facets/math/summed_sqdevs"
safe_require "facets/math/tau"
safe_require "facets/math/tgamma"
safe_require "facets/math/theil_index"
safe_require "facets/math/variance"

# Memoizable
safe_require "facets/memoizable"

# Memoizer
safe_require "facets/memoizer"

# Multipliers
safe_require "facets/multipliers"

# Multiton
safe_require "facets/multiton"

# Net Extensions
safe_require "facets/net/http"

# NullClass
safe_require "facets/nullclass"

# Opesc
safe_require "facets/opesc"

# OpenStruct Extensions
safe_require "facets/ostruct/each"
# safe_require 'facets/ostruct/initialize'
safe_require "facets/ostruct/merge"
safe_require "facets/ostruct/op_fetch"
safe_require "facets/ostruct/op_store"
safe_require "facets/ostruct/to_h"
safe_require "facets/ostruct/to_ostruct"

# Pathname Extensions
safe_require "facets/pathname/chdir"
safe_require "facets/pathname/empty"
safe_require "facets/pathname/exists"
safe_require "facets/pathname/glob"
safe_require "facets/pathname/home"
safe_require "facets/pathname/null"
safe_require "facets/pathname/op_div"
safe_require "facets/pathname/op_fetch"
safe_require "facets/pathname/outofdate"
safe_require "facets/pathname/readline"
safe_require "facets/pathname/root"
safe_require "facets/pathname/rootname"
safe_require "facets/pathname/safe"
safe_require "facets/pathname/split_root"
# Disabled: introduces null-byte issues in Puma request handling
# safe_require "facets/pathname/to_path"
safe_require "facets/pathname/to_str"
safe_require "facets/pathname/uptodate"
safe_require "facets/pathname/visit"
safe_require "facets/pathname/work"

# Platform
safe_require "facets/platform"

# Random
safe_require "facets/random"

# RbConfig
safe_require "facets/rbconfig"

# Set
safe_require "facets/set"

# Shellwords
safe_require "facets/shellwords"

# StringScanner
safe_require "facets/strscan"

# Thread
safe_require "facets/thread"

# Timer
safe_require "facets/timer"

# Tuple
safe_require "facets/tuple"

# URI Extensions
safe_require "facets/uri/cgi_escape"
safe_require "facets/uri/cgi_parse"
safe_require "facets/uri/cgi_unescape"
safe_require "facets/uri/decode"
safe_require "facets/uri/parameters"
safe_require "facets/uri/query"

# YAML Extensions
safe_require "facets/yaml/file"
safe_require "facets/yaml/kernel"
safe_require "facets/yaml/read"

# Zlib
safe_require "facets/zlib"
