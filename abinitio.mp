# abinitio
# version 3.0
graph "simple_graph"
{
    component "input_table" of "input_table" {
        parameter "filename" = "/data/input/data.txt";
        parameter "record_format" = "record
        (
            id: int;
            name: string;
            age: int;
        )";
    }

    component "reformat1" of "reformat" {
        parameter "transform" = "output :: record
        (
            id: id;
            name: name;
            age: age + 1;
        )";
    }

    component "output_table" of "output_table" {
        parameter "filename" = "/data/output/data_out.txt";
    }

    connect "input_table" to "reformat1";
    connect "reformat1" to "output_table";
}
