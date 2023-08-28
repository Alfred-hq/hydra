variable "POSTGRES_REPO" {
  default = "alfredcapital/hydra"
}

variable "SPILO_REPO" {
  default = "alfredcapital/hydra"
}

variable "SPILO_VERSION" {
  default = "v7"
}

variable "POSTGRES_BASE_VERSION" {
  default = "15"
}

variable "SPILO_POSTGRES_VERSION" {
  default = "15"
}

variable "PYTHON_VERSION" {
  default = "3.11"
}

group "default" {
  targets = ["spilo"]
}

target "shared" {
  platforms = [
    "linux/amd64",
    "linux/arm64"
  ]

  args = {
    TIMESTAMP = "${timestamp()}"
  }
}

target "postgres" {
  inherits = ["shared"]

  contexts = {
    postgres_base = "docker-image://postgres:${POSTGRES_BASE_VERSION}-bookworm"

    columnar = "target:columnar_${POSTGRES_BASE_VERSION}"
    http = "target:http_${POSTGRES_BASE_VERSION}"
    mysql = "target:mysql_${POSTGRES_BASE_VERSION}"
    multicorn = "target:multicorn_${POSTGRES_BASE_VERSION}"
    s3 = "target:s3_${POSTGRES_BASE_VERSION}"
    ivm = "target:ivm_${POSTGRES_BASE_VERSION}"
  }

  args = {
    POSTGRES_BASE_VERSION = "${POSTGRES_BASE_VERSION}"
    PYTHON_VERSION = "${PYTHON_VERSION}"
  }

  tags = [
    "${POSTGRES_REPO}:latest",
    "${POSTGRES_REPO}:${POSTGRES_BASE_VERSION}"
  ]
}

target "spilo" {
  inherits = ["shared"]

  dockerfile = "Dockerfile.spilo"

  contexts = {
    spilo_base = "docker-image://alfredcapital/splio:013baf818474aeeadc9c1464b290c0dae695629d"
    columnar_15 = "target:columnar_${POSTGRES_BASE_VERSION}"
    http_15 = "target:http_${POSTGRES_BASE_VERSION}"
    mysql_15 = "target:mysql_${POSTGRES_BASE_VERSION}"
    multicorn_15 = "target:multicorn_${POSTGRES_BASE_VERSION}"
    s3_15 = "target:s3_${POSTGRES_BASE_VERSION}"
    ivm_15 = "target:ivm_${POSTGRES_BASE_VERSION}"
  }

  args = {
    POSTGRES_BASE_VERSION = "${SPILO_POSTGRES_VERSION}"
    PYTHON_VERSION = "${PYTHON_VERSION}"
  }

  tags = [
    "${SPILO_REPO}:latest",
    "${SPILO_REPO}:${SPILO_VERSION}",
  ]
}

target "spilo_base" {
  inherits = ["shared"]

  contexts = {
    spilo_base = "https://github.com/Alfred-hq/spilo.git#production:postgres-appliance"
  }

}

target "http" {
  inherits = ["shared"]
  context = "third-party/http"
  target = "output"

  args = {
    PGSQL_HTTP_TAG = "v1.5.0"
  }
}

target "http_15" {
  inherits = ["http"]

  args = {
    POSTGRES_BASE_VERSION = 15
  }
}

target "s3" {
  inherits = ["shared"]
  context = "third-party/s3"
  target = "output"

  args = {
    ARROW_TAG = "apache-arrow-10.0.0"
    AWS_SDK_TAG = "1.10.57"
    PARQUET_S3_FDW_COMMIT = "3798786831635e5b9cce5dbf33826541c3852809"
  }
}

target "s3_15" {
  inherits = ["s3"]

  contexts = {
    postgres_base = "docker-image://postgres:15-bookworm"
  }

  args = {
    POSTGRES_BASE_VERSION = 15
  }

}

target "s3_spilo_15" {
  inherits = ["s3"]

  contexts = {
    postgres_base = "target:spilo_base"
  }

  args = {
    POSTGRES_BASE_VERSION = 15
  }
}

target "mysql" {
  inherits = ["shared"]
  context = "third-party/mysql"
  target = "output"

  args = {
    MYSQL_FDW_TAG = "REL-2_8_0"
  }
}

target "mysql_15" {
  inherits = ["mysql"]

  contexts = {
    postgres_base = "docker-image://postgres:15-bookworm"
  }

  args = {
    POSTGRES_BASE_VERSION = 15
  }
}

target "multicorn" {
  inherits = ["shared"]
  context = "third-party/multicorn"
  target = "output"

  args = {
    PYTHON_VERSION = "${PYTHON_VERSION}"
    MULTICORN_TAG  = "b68b75c253be72bdfd5b24bf76705c47c238d370"
    S3CSV_FDW_COMMIT = "f64e24f9fe3f7dbd1be76f9b8b3b5208f869e5e3"
    GSPREADSHEET_FDW_COMMIT = "d5bc5ae0b2d189abd6d2ee4610bd96ec39602594"
  }
}

target "multicorn_15" {
  inherits = ["multicorn"]

  contexts = {
    postgres_base = "docker-image://postgres:15-bookworm"
  }

  args = {
    POSTGRES_BASE_VERSION = 15
  }
}

target "columnar" {
  inherits = ["shared"]
  context = "columnar"
  target = "output"
}

target "columnar_15" {
  inherits = ["columnar"]

  args = {
    POSTGRES_BASE_VERSION = 15
  }
}

target "ivm" {
  inherits = ["shared"]
  context = "third-party/ivm"
  target = "output"

  args = {
    PGSQL_IVM_TAG = "v1.5.1"
  }
}

target "ivm_15" {
  inherits = ["ivm"]

  contexts = {
    postgres_base = "docker-image://postgres:15-bookworm"
  }

  args = {
    POSTGRES_BASE_VERSION = 15
  }
}

target "ivm" {
  inherits = ["shared"]
  context = "third-party/ivm"
  target = "output"

  args = {
    PGSQL_IVM_TAG = "v1.5.1"
  }
}
