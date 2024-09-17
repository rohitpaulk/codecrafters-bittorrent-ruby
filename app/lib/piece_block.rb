class PieceBlock
  attr_reader :piece
  attr_reader :index
  attr_reader :start_byte
  attr_reader :length

  def initialize(piece, index, start_byte, length)
    @piece = piece
    @index = index
    @start_byte = start_byte
    @length = length
  end

  def to_s
    "<PieceBlock(piece: #{@piece.index}, index: #{@index}, start_byte: #{@start_byte}, length: #{@length})>"
  end
end
