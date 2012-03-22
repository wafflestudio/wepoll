class SortedArray
  constructor:(@array = [],options = {})->
    @compare = options.compare if options.compare
  
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
 

