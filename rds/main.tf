resource "aws_db_instance" "main" {
    allocated_storage    = 10
    db_name              = "test_main"
    engine               = "postgres"
    engine_version       = "16.3"
    instance_class       = "db.t4g.micro"
    username             = "Master"
    password             = "Passw0rd"
    skip_final_snapshot  = true
}