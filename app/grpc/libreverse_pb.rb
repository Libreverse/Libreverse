# frozen_string_literal: true

# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: libreverse.proto

require "google/protobuf"

descriptor_data = "\n\x10libreverse.proto\x12\nlibreverse\"\x1a\n\x18GetAllExperiencesRequest\"\"\n\x14GetExperienceRequest\x12\n\n\x02id\x18\x01 \x01(\x05\"M\n\x17\x43reateExperienceRequest\x12\r\n\x05title\x18\x01 \x01(\t\x12\x13\n\x0b\x64\x65scription\x18\x02 \x01(\t\x12\x0e\n\x06\x61uthor\x18\x03 \x01(\t\"\x8d\x01\n\x17UpdateExperienceRequest\x12\n\n\x02id\x18\x01 \x01(\x05\x12\x12\n\x05title\x18\x02 \x01(\tH\x00\x88\x01\x01\x12\x18\n\x0b\x64\x65scription\x18\x03 \x01(\tH\x01\x88\x01\x01\x12\x13\n\x06\x61uthor\x18\x04 \x01(\tH\x02\x88\x01\x01\x42\x08\n\x06_titleB\x0e\n\x0c_descriptionB\t\n\x07_author\"%\n\x17\x44\x65leteExperienceRequest\x12\n\n\x02id\x18\x01 \x01(\x05\"&\n\x18\x41pproveExperienceRequest\x12\n\n\x02id\x18\x01 \x01(\x05\"\x1e\n\x1cGetPendingExperiencesRequest\"#\n\x14GetPreferenceRequest\x12\x0b\n\x03key\x18\x01 \x01(\t\"2\n\x14SetPreferenceRequest\x12\x0b\n\x03key\x18\x01 \x01(\t\x12\r\n\x05value\x18\x02 \x01(\t\"\'\n\x18\x44ismissPreferenceRequest\x12\x0b\n\x03key\x18\x01 \x01(\t\"+\n\x1d\x41\x64minApproveExperienceRequest\x12\n\n\x02id\x18\x01 \x01(\x05\"\x9a\x01\n\nExperience\x12\n\n\x02id\x18\x01 \x01(\x05\x12\r\n\x05title\x18\x02 \x01(\t\x12\x13\n\x0b\x64\x65scription\x18\x03 \x01(\t\x12\x0e\n\x06\x61uthor\x18\x04 \x01(\t\x12\x10\n\x08\x61pproved\x18\x05 \x01(\x08\x12\x12\n\ncreated_at\x18\x06 \x01(\t\x12\x12\n\nupdated_at\x18\x07 \x01(\t\x12\x12\n\naccount_id\x18\x08 \x01(\x05\"b\n\x12\x45xperienceResponse\x12*\n\nexperience\x18\x01 \x01(\x0b\x32\x16.libreverse.Experience\x12\x0f\n\x07success\x18\x02 \x01(\x08\x12\x0f\n\x07message\x18\x03 \x01(\t\"d\n\x13\x45xperiencesResponse\x12+\n\x0b\x65xperiences\x18\x01 \x03(\x0b\x32\x16.libreverse.Experience\x12\x0f\n\x07success\x18\x02 \x01(\x08\x12\x0f\n\x07message\x18\x03 \x01(\t\"2\n\x0e\x44\x65leteResponse\x12\x0f\n\x07success\x18\x01 \x01(\x08\x12\x0f\n\x07message\x18\x02 \x01(\t\"R\n\x12PreferenceResponse\x12\x0b\n\x03key\x18\x01 \x01(\t\x12\r\n\x05value\x18\x02 \x01(\t\x12\x0f\n\x07success\x18\x03 \x01(\x08\x12\x0f\n\x07message\x18\x04 \x01(\t2\xee\x07\n\x11LibreverseService\x12Z\n\x11GetAllExperiences\x12$.libreverse.GetAllExperiencesRequest\x1a\x1f.libreverse.ExperiencesResponse\x12Q\n\rGetExperience\x12 .libreverse.GetExperienceRequest\x1a\x1e.libreverse.ExperienceResponse\x12W\n\x10\x43reateExperience\x12#.libreverse.CreateExperienceRequest\x1a\x1e.libreverse.ExperienceResponse\x12W\n\x10UpdateExperience\x12#.libreverse.UpdateExperienceRequest\x1a\x1e.libreverse.ExperienceResponse\x12S\n\x10\x44\x65leteExperience\x12#.libreverse.DeleteExperienceRequest\x1a\x1a.libreverse.DeleteResponse\x12Y\n\x11\x41pproveExperience\x12$.libreverse.ApproveExperienceRequest\x1a\x1e.libreverse.ExperienceResponse\x12\x62\n\x15GetPendingExperiences\x12(.libreverse.GetPendingExperiencesRequest\x1a\x1f.libreverse.ExperiencesResponse\x12Q\n\rGetPreference\x12 .libreverse.GetPreferenceRequest\x1a\x1e.libreverse.PreferenceResponse\x12Q\n\rSetPreference\x12 .libreverse.SetPreferenceRequest\x1a\x1e.libreverse.PreferenceResponse\x12Y\n\x11\x44ismissPreference\x12$.libreverse.DismissPreferenceRequest\x1a\x1e.libreverse.PreferenceResponse\x12\x63\n\x16\x41\x64minApproveExperience\x12).libreverse.AdminApproveExperienceRequest\x1a\x1e.libreverse.ExperienceResponseB\x13\xea\x02\x10Libreverse::Grpcb\x06proto3"

pool = Google::Protobuf::DescriptorPool.generated_pool
pool.add_serialized_file(descriptor_data)

module Libreverse
  module Grpc
    GetAllExperiencesRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("libreverse.GetAllExperiencesRequest").msgclass
    GetExperienceRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("libreverse.GetExperienceRequest").msgclass
    CreateExperienceRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("libreverse.CreateExperienceRequest").msgclass
    UpdateExperienceRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("libreverse.UpdateExperienceRequest").msgclass
    DeleteExperienceRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("libreverse.DeleteExperienceRequest").msgclass
    ApproveExperienceRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("libreverse.ApproveExperienceRequest").msgclass
    GetPendingExperiencesRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("libreverse.GetPendingExperiencesRequest").msgclass
    GetPreferenceRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("libreverse.GetPreferenceRequest").msgclass
    SetPreferenceRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("libreverse.SetPreferenceRequest").msgclass
    DismissPreferenceRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("libreverse.DismissPreferenceRequest").msgclass
    AdminApproveExperienceRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("libreverse.AdminApproveExperienceRequest").msgclass
    Experience = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("libreverse.Experience").msgclass
    ExperienceResponse = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("libreverse.ExperienceResponse").msgclass
    ExperiencesResponse = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("libreverse.ExperiencesResponse").msgclass
    DeleteResponse = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("libreverse.DeleteResponse").msgclass
    PreferenceResponse = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("libreverse.PreferenceResponse").msgclass
  end
end
