class ListNode
  attr_accessor :val, :next

  def initialize(val = 0, _next = nil)
    @val = val
    @next = _next
  end
end

def add_two_numbers(l1, l2)
  l1_nro = concat_node_values(l1).to_i
  l2_nro = concat_node_values(l2).to_i
  value = l1_nro + l2_nro

  sum_values = value.to_s.chars.reverse
  nn = build_nodes(sum_values)
  concat_node_values(nn).chars.map{|c| c.to_i}
end

def build_nodes(list)
  value = list.pop
  return ListNode.new(value,nil) if list.size == 0

  node = build_nodes(list)
  ListNode.new(value,node)
end

def concat_node_values(node)
  node_values = [node.val]
  return node_values.join unless node.next

  node = node.next
  loop do
    node_values << node.val.to_s
    break unless node.next

    node = node.next
  end
  node_values.reverse.join
end

node1 = ListNode.new(2, ListNode.new(4, ListNode.new(3,nil)))
node2 = ListNode.new(5, ListNode.new(6, ListNode.new(4,nil)))

puts add_two_numbers(node1, node2)
#puts concat_node_values(add_two_numbers(ListNode.new(0,nil), ListNode.new(0,nil)))
