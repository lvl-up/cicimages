module Content
  class CourseContentRenderingError < StandardError
    def initialize(files)
      error = <<~ERROR
        Unable to render:
        - #{files.collect { |file| File.expand_path(file) }.join("\n- ")}"
      ERROR

      super error
    end

    def ==(other)
      other.is_a?(CourseContentRenderingError) && message == other.message
    end
  end

  class CommandError < StandardError
  end
end