package example

import "core:fmt"
import "core:slice"

// Struct
Person :: struct {
    name: string,
    age: int
}

// Enums
Directions :: enum {
    North,
    East,
    South,
    West
}

example :: proc() {
    fmt.println("heyo!")

    // Declarations
    CONST :int: 10
    a, b := 5, 6
    x := 5
    x = 8
    y: i8
    y = 4
    z: int = 12
    fmt.println(x,y,z)

    // If-else statements
    is_set := true
    if is_set {
        fmt.println("true")
    } else {
        fmt.println("false")
    }
    if c := do_thing(4); a < 8 {
        fmt.println("c is less than 8")
    }
    
    // Loops:
    for i in 0 ..< 10 {
        //fmt.println(i)
    }

    for i := 0; i < 10; i += 1 {
        //fmt.println(i)
    }
    text := "hello"
    #reverse for letter, i in text[0:] {
        fmt.println(letter, i)
    }
    for i in 0..<len(text) {
        fmt.println(rune(text[i]))
    }

    // Pointers
    d := 5
    modify_number(&d)
    fmt.println(d)

    // Arrays
    fmt.println()
    my_array : [5]int
    modify_array(&my_array)
    modify_any_array(my_array[:])
    for value in my_array {
        fmt.println(value)
    }
    my_array2 := [5]int {
        2, 4, 5, 6, 7
    }
    fmt.println()
    for value in my_array2 {
        fmt.println(value)
    }

    // Structs
    bob:= Person{"Bob", 50}
    fmt.println(bob.name)
    change_name(&bob)
    fmt.println(bob.name)

    // Dynamic arrays
    fmt.println()
    dynamic_array := make([dynamic]int)
    defer delete(dynamic_array)
    append(&dynamic_array, 22)
    append(&dynamic_array, 2)
    append(&dynamic_array, 5)
    for element in dynamic_array {
        fmt.println(element)
    }
    pop(&dynamic_array)
    unordered_remove(&dynamic_array,0)
    fmt.println()
    for element in dynamic_array {
        fmt.println(element)
    }
    append(&dynamic_array,10,2,44,50)
    slice.sort(dynamic_array[:])
    fmt.println()
    for element in dynamic_array {
        fmt.println(element)
    }

    name_to_age := make(map[string]int, context.temp_allocator)
    //defer delete(name_to_age)
    defer free_all(context.temp_allocator)
    name_to_age["John"] = 30
    name_to_age["Nick"] = 50
    fmt.println(name_to_age["Nick"])
    //age_value, name_existed := name_to_age["abc"]
    if value, existed := name_to_age["Nick"]; existed {
        fmt.println("Nick found")
    }
    if "John" in name_to_age {
        fmt.println("John found")
    }
    the_age := name_to_age["xyz"] or_else 20
    fmt.println(the_age)

}

do_thing :: proc(n: int) -> int {
    return n
}

modify_number :: proc(some_int: ^int) {
    some_int^ += 2
}

modify_array :: proc(some_array: ^[5]int) {
    some_array[2] = 2
}

modify_any_array :: proc(some_array: []int) {
    some_array[3] = 3
}

change_name :: proc(some_person: ^Person) {
    some_person.name = "johhny"
}
