class TimelineArray
  constructor: (@array = [], options = {})->
    #_.extend Backbone.Events
    @compare = options.compare if options.compare
    @func = @sparse
    @func = options.func if options.func

  add: (num)->
    for value,index in @array
      if @compare(num, value) < 0
        @array.splice(index,0,num)
        return @array

    @array.splice(@array.length,0,num)
    return @array


  remove: (num)->
    for value,index in @array
      if value == num
        @array.splice(index,1)
        return @array

    return @array

  compare: (a,b)->
    return a - b

  sortBy: (compare)->
    @compare = compare
    @array.sort(@compare)

  sortDesc: ()->
    desc = (a,b)->
      b - a
    @compare = desc
    @array.sort(desc)

  sortAsc: ()->
    asc = (a,b)->
      a - b
    @compare = asc
    @array.sort(asc)

  getValue: (num)->
    return func(num)

  getNum: (value)->
    

  func: (num)->
    value = num
    return value


  get_sparse_func: ()->
    
    self = this

    (num)->
      arr = self.arr
      # empty array
      return null if arr.length == 0 

      # borders
      if num < arr[0]
        return arr[0]
      if num > arr[arr.length-1]
        return arr[arr.length-1]
       
#      for value,index in arr
        

      

  # num -> value
  sparse: (num)->
    found_index  = -1
    nearest_index = null
    l_nearest_index = null
    r_nearest_index = null
    dist = null
    l_dist = null
    r_dist = null
    for n,index in @array
      if n == num
        return {found:true, index: index, value:num}
      if !dist? or dist > Math.abs(n - num)
        nearest_index = index
        dist = Math.abs(n - num)
      if num > n and (!l_dist? or l_dist > num - n)
        l_nearest_index = index
        l_dist = num - n
      if n > num and (!r_dist? or r_dist > n - num)
        r_nearest_index = index
        r_dist = n - num

    return {found:false, index:nearest_index, value:@array[nearest_index], index_left:l_nearest_index, value_left:@array[l_nearest_index], index_right:r_nearest_index, value_right:@array[r_nearest_index]}



TimelineArrayTest = ()->
  t = new TimelineArray()
  console.log(t, t.sparse(3))
  t.add(1)
  console.log(t, t.sparse(3))
  t.add(0)
  console.log(t, t.sparse(3))
  t.add(5)
  console.log(t, t.sparse(3))
  t.add(4)
  console.log(t, t.sparse(3))
  t.add(6)
  console.log(t, t.sparse(3))
  t.add(2)
  console.log(t, t.sparse(3))
  t.add(3)
  console.log(t, t.sparse(3))
  t.sortDesc()
  console.log(t)
  t.remove(1)
  console.log(t)
  t.remove(0)
  console.log(t)
  t.remove(5)
  console.log(t)
  t.remove(4)
  console.log(t)
  t.remove(6)
  console.log(t)
  t.remove(2)
  console.log(t)
  t.remove(3)
  console.log(t)



#TimelineArrayTest()

