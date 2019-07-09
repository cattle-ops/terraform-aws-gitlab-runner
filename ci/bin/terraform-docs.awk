# sources copied from https://github.com/cloudposse/build-harness

# This script converts Terraform 0.12 variables/outputs to something suitable for `terraform-docs`
# As of terraform-docs v0.6.0, HCL2 is not supported. This script is a *dirty hack* to get around it.
# https://github.com/segmentio/terraform-docs/
# https://github.com/segmentio/terraform-docs/issues/62

{
  if ( /\{/ ) {
    braceCnt++
  }

  if ( /\}/ ) {
    braceCnt--
  }

  # [START] variable or output block started
  if ($0 ~ /(variable|output) "(.*?)"/) {
    # [CLOSE] "default" block
    if (blockDefCnt > 0) {
      blockDefCnt = 0
    }
    blockCnt++
    print $0
  }

  # [START] multiline default statement started
  if (blockCnt > 0) {
    if ($1 == "default") {
      print $0
      if ($NF ~ /[\[\(\{]/) {
        blockDefCnt++
        blockDefStart=1
      }
    }
  }

  # [PRINT] single line "description"
  if (blockDefCnt == 0) {
    if ($1 == "description") {
      # [CLOSE] "default" block
      if (blockDefCnt > 0) {
        blockDefCnt = 0
      }
      print $0
    }
  }

  # [PRINT] single line "type"
  if (blockCnt > 0) {
    if ($1 == "type" ) {
      # [CLOSE] "default" block
      if (blockDefCnt > 0) {
        blockDefCnt = 0
      }
      type=$3
      if (type ~ "object") {
        print "  type = \"object\""
      } else {
        print "  type = \"" $3 "\""
      }
    }
  }

  # [CLOSE] variable/output block
  if (blockCnt > 0) {
    if (braceCnt == 0 && blockCnt > 0) {
      blockCnt--
      print $0
    }
  }

  # [PRINT] Multiline "default" statement
  if (blockCnt > 0 && blockDefCnt > 0) {
    if (blockDefStart == 1) {
      blockDefStart = 0
    } else {
      print $0
    }
  }
}
