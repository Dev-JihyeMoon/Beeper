package com.lastdance.beeper.service.impl;

import io.awspring.cloud.s3.ObjectMetadata;
import io.awspring.cloud.s3.S3Template;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class S3Uploader {
    private final S3Template s3Template;

    @Value("${spring.cloud.aws.s3.bucket}")
    private String bucket;

    // MultipartFile을 로컬 파일 변환 없이 스트림으로 바로 S3에 업로드
    public String upload(MultipartFile multipartFile) throws IOException {
        String fileName = UUID.randomUUID() + "_" + multipartFile.getOriginalFilename();

        s3Template.upload(
                bucket,
                fileName,
                multipartFile.getInputStream(),
                ObjectMetadata.builder()
                        .contentType(multipartFile.getContentType())
                        .build()
        );

        return s3Template.download(bucket, fileName).getURL().toString();
    }

}
