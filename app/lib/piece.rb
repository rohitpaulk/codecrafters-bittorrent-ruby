class Piece
  attr_reader :index
  attr_reader :length
  attr_reader :hash

  def initialize(index, length, hash)
    @index = index
    @length = length
    @hash = hash
  end

  def blocks
    @blocks ||= (0...@length).each_slice(2**14).each_with_index.map do |byte_range, index|
      PieceBlock.new(self, index, byte_range.first, byte_range.length)
    end
  end

  def to_s
    "<Piece(length: #{@length}, hash: #{@hash})>"
  end
end
