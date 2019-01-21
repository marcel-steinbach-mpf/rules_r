options(width=10000)
options(stringsAsFactors=FALSE)

printPackageDiff <- function(base_package_list, new_package_list) {

    configred.packages <- read.csv(base_package_list, header=TRUE, sep=",")
    resolved.packages <- read.csv(new_package_list, header=TRUE, sep=",")

    joined <- merge(x = resolved.packages, y = configred.packages, by = "Package", all.x = TRUE)

    new <- joined[ is.na(joined$Version.y) ,1:ncol(configred.packages)]
    write.table(new, file='new_packages.csv', col.names=FALSE, row.names=FALSE, sep=",")



    matched <- joined[ !is.na(joined$Version.y),]
    updated <- matched[ matched$Version.y != matched$Version.x , c(1:6)]
    write.table(updated[, 1:ncol(configred.packages)], file='updated_packages.csv', col.names=FALSE, row.names=FALSE, sep=",")


    updated.summary <- updated[, c(1,6,2)]

    names(updated.summary) <- NULL

    cat(sprintf("
Updated packages:
(replace the corresponding package entries in base '%s')
", base_package_list))

    if (nrow(updated.summary) != 0) {
        print(updated.summary, row.names=FALSE, right=FALSE)
        cat("\n")
        cat(readChar('updated_packages.csv', file.info('updated_packages.csv')$size))
    } else {
        cat("\nNone")
    }

    cat("\n")

    cat(sprintf("
New packages:
(add the following lines to the end of the base '%s')

%s

", base_package_list, if (nrow(new) == 0) "None" else    readChar('new_packages.csv', file.info('new_packages.csv')$size)))

}

writePackageDiff <- function(base_package_list, new_package_list, output) {

    configred.packages <- read.csv(base_package_list, header=TRUE, sep=",")
    resolved.packages <- read.csv(new_package_list, header=TRUE, sep=",")

    result <- merge(x = configred.packages, y = resolved.packages,  by = "Package", all.x = TRUE, all.y = TRUE)

    col_old <- colnames(result)
    col_new <- gsub(pattern = ".x",replacement = "", x  = col_old)
    colnames(result) <- col_new

    for (row in 1:nrow(result)) {
        # new packages
        if (is.na(result[row, "Version"]) ||
        (!is.na(result[row, "Version.y"]) && result[row, "Version"] != result[row, "Version.y"])) {
            result[row, "Version"] = result[row, "Version.y"]
            result[row, "sha256"] = result[row, "sha256.y"]
            if("mac_3_4_sha256.y" %in% colnames(result)) {
                result[row, "mac_3_4_sha256"] = result[row, "mac_3_4_sha256.y"]
            }
            if("mac_3_4_sha256.y" %in% colnames(result)) {
                result[row, "mac_3_5_sha256"] = result[row, "mac_3_5_sha256.y"]
            }

        }
    }

    write.table(result[, 1:ncol(configred.packages)], file=output, col.names=TRUE, row.names=FALSE, sep=",")
}

#printPackageDiff("external_packages.csv", "external_packages_caret.csv")
