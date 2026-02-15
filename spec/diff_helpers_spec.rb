require "spec_helper"
require "ostruct"

RSpec.describe DiffHelpers do
  let(:helper) { Object.new.extend(described_class) }

  describe "#parse_op" do
    it "maps '+' to DIFF_INS" do
      expect(helper.send(:parse_op, "+")).to eq(DiffHelpers::DIFF_INS)
    end

    it "maps '-' to DIFF_DEL" do
      expect(helper.send(:parse_op, "-")).to eq(DiffHelpers::DIFF_DEL)
    end

    it "maps ' ' to DIFF_NOOP" do
      expect(helper.send(:parse_op, " ")).to eq(DiffHelpers::DIFF_NOOP)
    end

    it "maps any other character to DIFF_NOOP" do
      expect(helper.send(:parse_op, "x")).to eq(DiffHelpers::DIFF_NOOP)
    end
  end

  describe "#diff_op_css_class" do
    it "returns 'code ins' for DIFF_INS" do
      expect(helper.diff_op_css_class(DiffHelpers::DIFF_INS)).to eq("code ins")
    end

    it "returns 'code del' for DIFF_DEL" do
      expect(helper.diff_op_css_class(DiffHelpers::DIFF_DEL)).to eq("code del")
    end

    it "returns 'code unchanged unmod' for DIFF_NOOP" do
      expect(helper.diff_op_css_class(DiffHelpers::DIFF_NOOP)).to eq("code unchanged unmod")
    end
  end

  describe "#parse_filename" do
    it "extracts the filename from unified diff headers" do
      headers = ["--- a/lib/foo.rb", "+++ b/lib/foo.rb"]
      expect(helper.send(:parse_filename, headers)).to eq("lib/foo.rb")
    end

    it "uses the 'to' filename when 'from' is /dev/null (new file)" do
      headers = ["--- /dev/null", "+++ b/lib/new_file.rb"]
      expect(helper.send(:parse_filename, headers)).to eq("lib/new_file.rb")
    end
  end

  describe "#parse_first_line_num" do
    it "extracts the starting line number from a chunk header" do
      expect(helper.send(:parse_first_line_num, "@@ -1,5 +1,7 @@")).to eq(1)
    end

    it "extracts larger line numbers" do
      expect(helper.send(:parse_first_line_num, "@@ -10,5 +42,7 @@")).to eq(42)
    end

    it "handles negative to-line (takes absolute value)" do
      expect(helper.send(:parse_first_line_num, "@@ -1,5 -10,3 @@")).to eq(10)
    end
  end

  describe "#parse_lines" do
    it "numbers context lines sequentially" do
      lines = [" line1", " line2", " line3"]
      result = helper.send(:parse_lines, lines, 1)
      expect(result.map(&:num)).to eq([1, 2, 3])
      expect(result.map(&:op)).to all(eq(DiffHelpers::DIFF_NOOP))
      expect(result.map(&:body)).to eq(["line1", "line2", "line3"])
    end

    it "numbers insertion lines" do
      lines = ["+added1", "+added2"]
      result = helper.send(:parse_lines, lines, 1)
      expect(result.map(&:num)).to eq([1, 2])
      expect(result.map(&:op)).to all(eq(DiffHelpers::DIFF_INS))
    end

    it "numbers deletion lines" do
      lines = ["-removed1", "-removed2"]
      result = helper.send(:parse_lines, lines, 1)
      expect(result.map(&:num)).to eq([1, 2])
      expect(result.map(&:op)).to all(eq(DiffHelpers::DIFF_DEL))
    end

    it "handles a deletion followed by an insertion" do
      lines = ["-old_line", "+new_line"]
      result = helper.send(:parse_lines, lines, 5)
      expect(result[0].num).to eq(5)
      expect(result[0].op).to eq(DiffHelpers::DIFF_DEL)
      # Single del-then-ins: run_length is 0 so no rewind occurs
      expect(result[1].num).to eq(6)
      expect(result[1].op).to eq(DiffHelpers::DIFF_INS)
    end

    it "rewinds line numbers after a multi-line deletion run followed by insertions" do
      lines = ["-del1", "-del2", "+ins1", "+ins2"]
      result = helper.send(:parse_lines, lines, 10)
      expect(result[0]).to have_attributes(num: 10, op: DiffHelpers::DIFF_DEL)
      expect(result[1]).to have_attributes(num: 11, op: DiffHelpers::DIFF_DEL)
      # Switching from DEL run (length 2) to INS: rewinds by run_length (1)
      expect(result[2]).to have_attributes(num: 11, op: DiffHelpers::DIFF_INS)
      expect(result[3]).to have_attributes(num: 12, op: DiffHelpers::DIFF_INS)
    end

    it "handles context then deletion then insertion" do
      lines = [" context", "-deleted", "+inserted", " more_context"]
      result = helper.send(:parse_lines, lines, 10)
      expect(result[0]).to have_attributes(num: 10, op: DiffHelpers::DIFF_NOOP, body: "context")
      expect(result[1]).to have_attributes(num: 11, op: DiffHelpers::DIFF_DEL, body: "deleted")
      expect(result[2]).to have_attributes(num: 11, op: DiffHelpers::DIFF_INS, body: "inserted")
      expect(result[3]).to have_attributes(num: 12, op: DiffHelpers::DIFF_NOOP, body: "more_context")
    end
  end

  describe "#parse_diff" do
    it "handles binary files" do
      diff = OpenStruct.new(
        diff: "Binary files a/image.png and b/image.png differ",
        a_blob: OpenStruct.new(data: ""),
        b_blob: OpenStruct.new(data: "")
      )
      filename, lines = helper.parse_diff(diff)
      expect(lines).to eq([])
    end

    it "handles new files (a_blob is nil)" do
      diff = OpenStruct.new(
        diff: "--- /dev/null\n+++ b/lib/new.rb",
        a_blob: nil,
        b_blob: OpenStruct.new(data: "line1\nline2\nline3")
      )
      filename, lines = helper.parse_diff(diff)
      expect(filename).to eq("lib/new.rb")
      expect(lines.length).to eq(3)
      expect(lines.map(&:op)).to all(eq(DiffHelpers::DIFF_INS))
      expect(lines.map(&:num)).to eq([1, 2, 3])
    end

    it "handles modified files" do
      diff = OpenStruct.new(
        diff: "--- a/lib/foo.rb\n+++ b/lib/foo.rb\n@@ -1,3 +1,3 @@\n context\n-old\n+new\n context2",
        a_blob: OpenStruct.new(data: "context\nold\ncontext2"),
        b_blob: OpenStruct.new(data: "context\nnew\ncontext2")
      )
      filename, lines = helper.parse_diff(diff)
      expect(filename).to eq("lib/foo.rb")
      expect(lines[0]).to have_attributes(body: "context", op: DiffHelpers::DIFF_NOOP)
      expect(lines[1]).to have_attributes(body: "old", op: DiffHelpers::DIFF_DEL)
      expect(lines[2]).to have_attributes(body: "new", op: DiffHelpers::DIFF_INS)
      expect(lines[3]).to have_attributes(body: "context2", op: DiffHelpers::DIFF_NOOP)
    end
  end
end
