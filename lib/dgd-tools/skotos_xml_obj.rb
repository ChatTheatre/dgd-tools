require "dgd-tools/version"

# Nokogiri is unusually permissive as an XML parser, which is
# good - SkotOS XML objects don't parse with most XML parsers.
require "nokogiri"

require "tempfile"

module SkotOS; end

class SkotOS::XMLObject
    attr_reader :pretty

    def initialize(pretty)
        @pretty = pretty
    end

    def self.from_file(filename)
        # SkotOS files often have references to undefined namespaces,
        # but we can get Nokogiri to parse it.
        doc = Nokogiri::XML(File.read filename)

        remove_undiffed(doc)

        pretty = doc.to_xml(indent:3)
        #data = doc.to_hash
        #prune_whitespace(data)
        SkotOS::XMLObject.new pretty
    end

    def self.diff_between(obj1, obj2, o1_name: "Object 1", o2_name: "Object 2")
        of1 = Tempfile.new("skotos_xml_diff1_")
        of2 = Tempfile.new("skotos_xml_diff2_")

        begin
            of1.write(obj1.pretty)
            of2.write(obj2.pretty)
            of1.close
            of2.close

            # Diff 'fails' if there's a difference between the two files.
            diff = system_call("diff -c #{of1.path} #{of2.path}", fail_ok: true)
            diff.sub!(of1.path, o1_name)
            diff.sub!(of2.path, o2_name)
        ensure
            of1.unlink
            of2.unlink
        end
        diff
    end

    def self.diff_dirs(dir1, dir2)
        entries1 = Dir.glob("*", base: dir1).to_a
        entries2 = Dir.glob("*", base: dir2).to_a

        only_in_1 = entries1 - entries2
        only_in_2 = entries2 - entries1
        in_both = entries1 & entries2

        diff = []
        diff << "Only in first: #{only_in_1.join(", ")}" unless only_in_1.empty?
        diff << "Only in second: #{only_in_2.join(", ")}" unless only_in_2.empty?

        in_both.each do |file|
            in_1 = "#{dir1}/#{file}"
            in_2 = "#{dir2}/#{file}"
            if File.directory?(in_1) ^ File.directory?(in_2)
                diff << "Only a directory in one, not both: #{dir1}/#{file}"
            elsif File.directory?(in_1)
                d = diff_dirs(in_1, in_2)
                diff.concat(d)
            else
                o1 = from_file(in_1)
                o2 = from_file(in_2)
                diff << diff_between(o1, o2, o1_name: in_1, o2_name: in_2)
            end
        end
        diff
    end

    def self.remove_undiffed(doc)
        if doc.root && doc.root.element? && doc.root.attribute("owner")
            doc.root.remove_attribute("owner")
        end
    end

    def self.system_call(cmd, fail_ok: false)
        f = Tempfile.new("system_call_xml_diff_")
        begin
            puts "Running command: #{cmd.inspect}..."
            system(cmd, out: f)
            unless fail_ok || $?.success?
                f.rewind
                out = f.read
                raise "Error running command: #{cmd.inspect}!\n\nOutput:\n#{out}\n\n"
            end
            f.rewind
            return f.read
        ensure
            f.close
            f.unlink
        end
    end
end

=begin
# Abandoned approach follows
# Some code taken from: https://stackoverflow.com/a/10144623
class Nokogiri::XML::Node
  TYPENAMES = {1=>'element',2=>'attribute',3=>'plaintext',4=>'cdata',8=>'comment'}
  def to_hash
    {kind:TYPENAMES[node_type],name:name}.tap do |h|
      h.merge! nshref:namespace.href, nsprefix:namespace.prefix if namespace
      h.merge! text:text
      h.merge! attr:attribute_nodes.map(&:to_hash) if element?
      h.merge! kids:children.map(&:to_hash) if element?
    end
  end
end
class Nokogiri::XML::Document
  def to_hash; root.to_hash; end
end

class SkotOS::XMLObject
    OBJ_FIELDS = [:kind, :name, :text, :attr, :nshref, :nsprefix]
    def self.diff_between(obj1, obj2, diff = [])
        single_obj1 = obj1.slice(*OBJ_FIELDS)
        single_obj2 = obj2.slice(*OBJ_FIELDS)

        this_diff = []
        OBJ_FIELDS.each do |field|
            if single_obj1[field] != single_obj2[field]
                this_diff.concat ["+#{field}: #{single_obj2[field]}", "-#{field}: #{single_obj1[field]}"]
            end
        end

        single_obj1[:kids]

        diff
    end

    def self.prune_whitespace(data)
        data[:text].gsub!(/\W+/, " ")
        data[:text].strip!
        new_kids = data[:kids].flat_map do |node|
            if node[:kind] == "comment"
                []
            elsif node[:kind] == "plaintext"
                new_text = node[:text].gsub(/\W+/, " ").strip
                if new_text == ""
                    []
                else
                    node[:text] = new_text
                    [node]
                end
            elsif node[:kind] == "element" || node[:kind] == "attribute"
                node[:text].gsub!(/\W+/, " ")
                node[:text].strip!
                prune_whitespace(node)
                [node]
            else
                raise "Is this illegal or did I just not anticipate it?"
            end
        end
        data[:kids] = new_kids
        nil
    end
end
=end
